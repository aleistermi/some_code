from hdrh import histogram
import sys, traceback
import argparse
import logging
from datetime import datetime
import connection
import sfinspection_scan
import pandas as pd
import psycopg2
import time
from fuzzywuzzy import fuzz

#logging
logger= logging.getLogger('sfinspect')
logger.setLevel(logging.INFO)
ch = logging.StreamHandler()
logger.addHandler(ch)

#TABLE NAMES TO USE
RAW_INSPECTION_TBL ="rawinspection"
CLEAN_REST_TBL="cleanrest"
CLEAN_INSPECTION_TBL="cleaninspection"
JOINED_BIKE_INSPECTION_TBL="joinedinspbike"

def get_matches(df, results_dict):
    for i, row in df.iterrows():
        by_set_name = fuzz.token_set_ratio(row['name_left'], row['name_right'])
        by_set_address = fuzz.token_set_ratio(row['address_left'], row['address_right'])
        by_sequence_phone_number = fuzz.token_sort_ratio(row['phone_number_left'], row['phone_number_right'])
        if row['phone_number_left']==None and row['phone_number_right']==None:
            total_score = (0.7*by_set_name + 0.2*by_set_address)/90
        else:
            total_score = 0.7*by_set_name + 0.2*by_set_address + 0.1*by_sequence_phone_number

        if total_score > 75 and total_score < 100:
            left = row['name_left'],row['address_left'], row['phone_number_left']
            right = row['name_right'],row['address_right'], row['phone_number_right']
            if left not in results_dict.keys():
                results_dict[left] = [right]
            else:
                results_dict[left].append(right)

def unique_matches(allmatch_dict):
    new = {}
    for k, v in allmatch_dict.items():
        if not set(v).intersection(set(new.keys())):
            new[k] = v
    return new


class client:
    def __init__(self):
        self.dbname=connection.dbname
        self.dbhost=connection.dbhost
        self.dbport=connection.dbport
        self.dbusername=connection.dbusername
        self.dbpasswd=connection.dbpasswd
        self.conn = None
        self.cur = None



    # open a connection to a psql database, using the self.dbXX parameters
    def open_connection(self):
        logger.debug("Opening a Connection")
        if not self.conn or self.conn.closed:
            self.conn = psycopg2.connect(dbname=self.dbname,
                                         user=self.dbusername,
                                         host=self.dbhost,
                                         password=self.dbpasswd,
                                         port=self.dbport)
            self.conn.set_session(autocommit=True)
        self.cur = self.conn.cursor()


    # Close any active connection(should be able to handle closing a closed conn)
    def close_connection(self):
        logger.debug("Closing Connection")
        self.cur.close()
        self.conn.close()


    # Load the inspection data via TSV loading or via hbase. Use happybase as the library for hbase
    # hbase == hbase
    def load_inspection(self, limit_load=None, load_file=None,load_hbase="addison.cs.uchicago.edu,sfinspection"):
        logger.debug("Loading Inspection")
        if load_file == None and load_hbase==None:
            raise Exception("No Load Details Provided")
        elif load_file != None and load_hbase != None:
            raise Exception("Conflicting Load Details Provided")
        elif load_hbase:
            if "," not in load_hbase:
                raise Exception("load_hbase should be hostname,tablename")
            hbase_host,hbase_table = load_hbase.split(",")

        inspection_scan.scan_data(host=hbase_host, port=9090, namespace="sffood", table_name=hbase_table,hbase_separator=":")

    # Clean restaurants table to have a single correct restaurant entry for all likely variations
    def clean_dirty_inspection(self):
        logger.debug("Cleaning Dirty Data")
        start_time = time.time()
        self.open_connection()
        my_file = open('data/sfinspection_scanned.csv', 'r')
        self.cur.copy_expert('''COPY sfinspection FROM STDIN WITH CSV HEADER DELIMITER '|' ''', my_file)

        query = "SELECT a.business_name AS name_left, a.business_address AS address_left, a.business_phone_number AS phone_number_left,\
                b.business_name AS name_right, b.business_address AS address_right, b.business_phone_number AS phone_number_right\
                FROM (SELECT business_name, business_address, business_phone_number, business_postal_code\
                    FROM sfinspection\
                    WHERE business_postal_code = '{}'\
                    AND LENGTH(business_name) BETWEEN {} AND {}\
                    GROUP BY business_name, business_address, business_phone_number, business_postal_code) a,\
                    (SELECT business_name, business_address, business_phone_number, business_postal_code\
                    FROM sfinspection\
                    WHERE business_postal_code = '{}'\
                    AND LENGTH(business_name) BETWEEN {} AND {}\
                    GROUP BY business_name, business_address, business_phone_number, business_postal_code) b;"

        postal_codes_list = ['94105', '94115', '94117', '94103', '94114', '94110',
                            '94122', '94102', '94112', '94107', '94132', '94104', '94124',
                            '94158', '94134', '94111', '94118', '94127', '94116', '94108',
                            '94133', '94109', '94301', '94123', '94131', '941033148', '00000',
                            '94130', '94101', '94188', '94143', '94120', '94544', '94014',
                            '95105', '941', '92672', '94013', 'CA', '94080', '941102019',
                            '94602', '94901', '94129', 'Ca', '99999', '94121']

        #postal_codes_list = ['94121', '94105']

        intervals_list = [[2,11], [12, 14], [15, 18], [19, 23], [24, 69]]

        matches = {}

        for postal_code in postal_codes_list:
            count=0
            for interval in intervals_list:
                low = interval[0]
                high = interval[1]
                df = pd.read_sql(query.format(postal_code, low, high, postal_code, low, high), con=self.conn)
                print(list(df))
                get_matches(df, matches)
                duration = time.time() - start_time
                print(duration)
                count+=1
                print(count)

        new = unique_matches(matches)
        values = list(new.values())
        to_change = [j for i in values for j in i]

        dirty =  pd.read_sql("SELECT * FROM sfinspection", self.conn)
        change = []
        for i, row in dirty.iterrows():
            if (row['business_name'], row['business_address'], row['business_phone_number']) in to_change:
                change.append(i)
        no_change = [i for i in range(len(dirty)) if i not in change]
        change_df = dirty.iloc[change, :]
        no_change_df = dirty.iloc[no_change, :]

        final_df = []
        for k, v in new.items():
            for i, row in change_df.iterrows():
                if (row['business_name'], row['business_address'], row['business_phone_number']) in v:
                    final_df.append([k[0], k[1], row['business_city'], row['business_state'], row['business_postal_code'],
                        row['business_latitude'], row['business_longitude'], k[2], row['inspection_id'], row['inspection_date'],
                        row['inspection_score'], row['inspection_type'], row['violation_id'], row['violation_description'],
                        row['risk_category']])
        columns_names = ['business_name', 'business_address', 'business_city', 'business_state',
                        'business_postal_code', 'business_latitude', 'business_longitude',
                        'business_phone_number', 'inspection_id', 'inspection_date',
                        'inspection_score', 'inspection_type', 'violation_id',
                        'violation_description', 'risk_category']
        changed_df = pd.DataFrame(final_df, columns=columns_names)

        all_cleaned = no_change_df.append(changed_df)
        all_cleaned.to_csv('data/cleaned.csv', sep='|', index=False)

        clean_file = open('data/cleaned.csv', 'r')
        self.cur.copy_expert('''COPY sfinspection_temp FROM STDIN WITH CSV HEADER DELIMITER '|' ''', clean_file)

        self.cur.execute('''INSERT INTO cleanrest (business_name, business_address, business_city, business_state,
                        business_postal_code, business_latitude, business_longitude, business_phone_number)
                        SELECT business_name, business_address, business_city, business_state, business_postal_code,
                            business_latitude, business_longitude, business_phone_number
                        FROM sfinspection_temp;''')

        self.cur.execute('''INSERT INTO cleaninspection (business_name, business_address, inspection_id, inspection_date,
                        inspection_score, inspection_type, violation_id, violation_description, risk_category)
                        SELECT business_name, business_address, inspection_id, inspection_date, inspection_score,
                            inspection_type, violation_id, violation_description, risk_category
                        FROM sfinspection_temp;''')


        return
    # create tables
    def build_tables(self):
        logger.debug("Building Tables")
        self.open_connection()
        self.cur.execute("DROP TABLE IF EXISTS sfinspection;")
        self.cur.execute("DROP TABLE IF EXISTS sfinspection_temp;")
        self.cur.execute("DROP TABLE IF EXISTS cleaninspection;")
        self.cur.execute("DROP TABLE IF EXISTS cleanrest;")
        self.cur.execute("DROP TABLE IF EXISTS joinedinspbike")

        self.cur.execute('''CREATE TABLE sfinspection(
            business_name             varchar(100),
            business_address          varchar(100),
            business_city             varchar(100),
            business_state            varchar(100),
            business_postal_code      varchar(100),
            business_latitude         float8,
            business_longitude        float8,
            business_phone_number     varchar(20),
            inspection_id             varchar(100),
            inspection_date           date,
            inspection_score          float8,
            inspection_type           varchar(100),
            violation_id              varchar(100),
            violation_description     varchar(100),
            risk_category             varchar(100));''')

        self.cur.execute('''CREATE TABLE sfinspection_temp(
            business_name             varchar(100),
            business_address          varchar(100),
            business_city             varchar(100),
            business_state            varchar(100),
            business_postal_code      varchar(100),
            business_latitude         float8,
            business_longitude        float8,
            business_phone_number     varchar(20),
            inspection_id             varchar(100),
            inspection_date           date,
            inspection_score          float8,
            inspection_type           varchar(100),
            violation_id              varchar(100),
            violation_description     varchar(100),
            risk_category             varchar(100));''')

        self.cur.execute('''CREATE TABLE cleanrest (
            business_name             varchar(100),
            business_address          varchar(100),
            business_city             varchar(100),
            business_state            varchar(100),
            business_postal_code      varchar(100),
            business_latitude         float8,
            business_longitude        float8,
            business_phone_number     varchar(20)
            );''')

        self.cur.execute('''CREATE TABLE cleaninspection (
            business_name             varchar(100),
            business_address          varchar(100),
            inspection_id             varchar(100),
            inspection_date           date,
            inspection_score          float8,
            inspection_type           varchar(100),
            violation_id              varchar(100),
            violation_description     varchar(100),
            risk_category             varchar(100)
            );''')

        self.cur.execute('''CREATE TABLE joinedinspbike (
            duration int,
            bike_id int,
            violation_id              varchar(100),
            inspection_date           date
            );''')


    #add any needed indexes
    def build_indexes(self):
        logger.debug("Building Indexes")
        self.open_connection()
        self.cur.execute('''CREATE INDEX b_zip ON sfinspection USING BTREE (business_postal_code)''')
        #self.cur.execute('''CREATE INDEX b_name ON sfinspection USING BTREE (business_name)''')
