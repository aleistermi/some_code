
-- TABLE FOR Post-Survey 2016
--1) Create table
    DROP TABLE IF EXISTS dga.post_2016;
    CREATE TABLE dga.post_2016 (
      personid_post INT,
      registered_post INT,
      voterbaseid_post VARCHAR (255),
      able_to_vote_post INT,
      post_qvote INT,
      post_gov_vote VARCHAR (255),
      party_id_post VARCHAR (255),
      close_to_party_id_post VARCHAR (255),
      make_up_mind_post INT,
      confidence_vote INT,
      learned_makeup_post VARCHAR (255),
      gender_post INT,
      age_post INT,
      school_post INT);
-- 2) Insert INTO/FROM TABLES
      INSERT INTO dga.post_2016 (personid_post ,
                            voterbaseid_post ,
                            registered_post ,
                            able_to_vote_post ,
                            post_gov_vote ,
                            party_id_post,
                            close_to_party_id_post ,
                            make_up_mind_post ,
                            confidence_vote ,
                            gender_post ,
                            age_post ,
                            school_post )
      SELECT CAST(personid as INT),
             voterba ,
             s1,
             coalesce(q1,q2),
             CASE  -- This is the code for the dependent variable, post_survey in 2016
                WHEN v1MO = 1 OR v1IN = 1 OR  V1WV = 1 OR v1MT = 1  THEN 'DEM'
                WHEN v1MO = 2 OR  v1IN = 2 OR  V1WV = 2 OR v1MT = 2  THEN 'REP'
                WHEN v1MO = 3 OR v1MO = 4 OR v1MO =5 OR  v1IN =3 OR
                V1WV = 3 OR V1WV =4 OR v1MT = 3 THEN 'IND'
                WHEN v1MO = 7 OR v1IN =5  OR  V1WV =6 OR  v1MT=5 THEN 'OTHER'
                WHEN v1MO = 6 OR v1MO = 8 OR v1IN = 4  OR v1IN = 6 OR  V1WV =5  OR  V1WV = 6  OR V1MT = 4 OR v1MT = 6
                THEN 'DIDNT VOTE/REFUSED'
                END ,
            p1x,
            p1y,
            q3,
            q4,
            gender,
            d101,
            d102
      FROM dga.dga_post_survey; -- This is the 2016 post_survey

      ALTER TABLE dga.post_2016
      ADD year_post INT;
      UPDATE dga.post_2016
      SET year_post = 2016;

  --TABLE FOR Post-Survey 2017
  --1) Create table
  DROP TABLE IF EXISTS dga.post_2017;
  CREATE TABLE dga.post_2017 (personid_post INT,
                          registered_post INT,
                          voterbaseid_post VARCHAR (255),
                          able_to_vote_post INT,
                          post_qvote INT,
                          post_gov_vote VARCHAR (255),
                          party_id_post VARCHAR (255),
                          close_to_party_id_post VARCHAR (255),
                          make_up_mind_post INT,
                          confidence_vote INT,
                          learned_makeup_post VARCHAR (255),
                          gender_post INT,
                          age_post INT,
                          school_post INT);
-- 2) Insert INTO/FROM TABLES
      INSERT INTO dga.post_2017 (personid_post ,
                            voterbaseid_post ,
                            registered_post ,
                            able_to_vote_post ,
                            post_qvote,
                            post_gov_vote ,
                            make_up_mind_post,
                            learned_makeup_post,
                            gender_post ,
                            age_post  )
      SELECT CAST(personid as INT),
      tsmtvoterbaseid,
      s1,
      q1,
      qvote,
      (CASE   -- This is the code for the dependent variable, post_survey in 2017
        WHEN v1 = 1  THEN 'DEM'
        WHEN v1 = 2 THEN 'REP'
        WHEN  v1 = 4  or v1=6  THEN 'DIDNT VOTE/REFUSED'
        WHEN  v1 = 3  THEN 'OTHER'
        ELSE NULL END) AS pre_gov_vote,
      q2,
      q3,
      d100,
      dage_1
      FROM  dga.dga_post_survey2017;

      ALTER TABLE dga.post_2017
      ADD year_post INT;
      UPDATE dga.post_2017
      SET year_post = 2017;

-- COMBINE BOTH POST SURVEYS

DROP TABLE IF EXISTS dga.DGA_POST2016_2017;
CREATE TABLE dga.DGA_POST2016_2017 AS (SELECT * FROM post_2016 UNION ALL (SELECT * FROM post_2017));

-- CREATE A TABLE WITH THE MOST RECENT PERSONID

DROP TABLE IF EXISTS dga.switcher_latest_id;
CREATE table dga.switcher_latest_id AS
  WITH a AS
      (SELECT dga_temp.personid,
              dga_temp.date,
              ROW_NUMBER() OVER (PARTITION BY dga_temp.personid ORDER BY dga_temp.date DESC) AS rownum
  FROM dga.DGA_switcher2016_2017  dga_temp
  INNER JOIN dga.DGA_switcher2016_2017 p
  ON dga_temp.personid=p.personid)
  SELECT * FROM a WHERE rownum=1;

-- WE PRESERVE THE ID'S THAT ARE IN THE DGA_SWITCHER_LATEST_ID
DROP TABLE IF EXISTS dga.pre_switcher_unique_ID;
CREATE TABLE dga.pre_switcher_unique_ID AS (SELECT a.*
                                            FROM  dga.DGA_switcher2016_2017 a
                                            INNER JOIN dga.switcher_latest_id b
                                            ON a.personid=b.personid and b.date=a.date)
                                            UNION ALL
                                            (SELECT * from  dga.DGA_switcher2016_2017 where date is null);

-- COMBINE BOTH PRE AND POST SURVEYS
DROP TABLE IF EXISTS dga.switcher_pre_and_post_16_17;
CREATE TABLE dga.switcher_pre_and_post_16_17 AS (select a.*,
                                                        b.* as year_post
                                                 FROM dga.pre_switcher_unique_ID a
                                                 INNER JOIN  dga.DGA_POST2016_2017 b
                                                 ON a.personid=b.personid_post);


-- ADD COLUMNS --> Need to ommit repeated code. ASK EMILY/LARA/STACKOVERFLOW
ALTER TABLE dga.switcher_pre_and_post_16_17 ADD switcher_updated INT;
ALTER TABLE dga.switcher_pre_and_post_16_17 ADD whole_breaker INT;
ALTER TABLE dga.switcher_pre_and_post_16_17 ADD  dem_breaker INT;
ALTER TABLE dga.switcher_pre_and_post_16_17 ADD  rep_breaker INT;

--CREATE THE SWITCHER/BREAKER VARIABLES
UPDATE dga.switcher_pre_and_post_16_17
      SET switcher_updated =
         (CASE WHEN pre_gov_vote='DEM' and (post_gov_vote = 'REP' or post_gov_vote = 'IND') then 1
          WHEN pre_gov_vote='REP' and (post_gov_vote = 'DEM' or post_gov_vote = 'IND') then 1
          WHEN pre_gov_vote='IND' and (post_gov_vote = 'REP' or post_gov_vote = 'DEM') then 1
         ELSE 0 END);
UPDATE dga.switcher_pre_and_post_16_17
      SET   whole_breaker =
         (CASE WHEN (pre_gov_vote='IND'  or pre_gov_vote='DK/UND/REF' or pre_gov_vote='OTHER') and
         (post_gov_vote = 'REP' or post_gov_vote = 'DEM') then 1
         ELSE 0 END);
UPDATE dga.switcher_pre_and_post_16_17
       SET  dem_breaker =
          (CASE WHEN (pre_gov_vote='IND'  or pre_gov_vote='DK/UND/REF' or pre_gov_vote='OTHER') and  ( post_gov_vote = 'DEM') then 1
          ELSE 0 END);
UPDATE dga.switcher_pre_and_post_16_17
        SET  rep_breaker =
          (CASE WHEN (pre_gov_vote='IND'  or pre_gov_vote='DK/UND/REF' or pre_gov_vote='OTHER') and  ( post_gov_vote = 'REP') then 1
          ELSE 0 END);
