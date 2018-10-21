/* ############################################### dga.DGA_swichter2016_2017 Table ############################################
####################
# Created by @Aleister Montfort#
#          07/01/2018          #

'''
This code creates two tables for 2016 and 2017 containing information of voters who
were recontacted to determine if they switched their vote.
The 2016 table is a combination of three tables:
dga.dga_pre_survey_response, dga_master_qts, and dga_master_responses.
For the 2016 data, masterquestions were used to unify responses across different pollsters,
whereas for 2017, all responses come from surveys polled by GSG.

The 2017 table mostly comes from table switcher.master_switch_data, and additional
questions were joined from the dga.va_mm_stacked_waves table.
To construct the final table, these two tables were stacked (SQL UNION).
The variables included in the dga.DGA_swichter2016_2017 table are:

  -- personid <- Unique identifier
    Note: some personid are missing values. Check

  -- date <- Date of the survey. In the 2017 wave, it corresponds to the 'start_date'
     variable.

  -- voterbaseid <- It is the same variable as 'voterbaseid'

  -- likelihood_vote <- It corresponds to the masterquestion 'VOTE_LIKELIHOOD' in the 2016,
     and to question S2 in GSG Interview.
     On November 7th, there will be an election for Governorin Virginiaand other offices.
     How likely are you to vote in this election? How likely are you to vote in this election?
     Will you definitely vote, probably vote, are the chances 50-50, probably not vote,
     or definitely not vote?
     1 Definitely
     2 Probably
     3 Chance 50-50
     4 Probably not
     5 Definitely not
     6 Don’t know/Refused

  -- qparty <- Party ID. Masterquestion: PARTY_1; Question P1X in GSG Questionnaire (GSG-Q).
     No matter how you may be planning to vote this year, when it comes to politics,
     do you generally think of yourself as a strong Democrat, not very strong Democrat,
     strong Republican, not very strong Republican, or independent?
     (1,2)  # Democrat - Strong/weak Democrat
     (3,4)  # Republicans - Strong/weak Republican
     5      # Independent/Other
     6      # Undecided, Refused, Dont know

  -- close_to_Party_ID <- Party ID. Masterquestion: PARTY_2. Question P1Y in GSG GSG-Q
     Do you think of yourself as closer to the Democratic Party or the Republican Party?
     (1,2) Closer to Democrats/Republicans
      3    Neither/independent
      4    Dont know

  -- dem_favorability <- Favorable opinion. Masterquestion: FAV_DEM. Question 5 in GSG-Q
  Do you have a favorable or unfavorable opinion of (DEMOCRAT CANDIDATE)

  -- rep_favorability <- Favorable opinion. Masaterquestion: FAV_DEM. Question 6 in GSG-Q
  Do you have a favorable or unfavorable opinion of (REPUBLICAN CANDIDATE)

  -- qvote <- Support/Vote. Masterquestion: GOV_VOTE. Question V1 in GSG-Q
     If the election for governor were held today, would you vote for Democrat XX,
     Republican XX or Libertarian XX?
      1  # Support/vote Ralph Northam
      2  # Lean Ralph Northam
      3  # Support/vote Ed Gillespie
      4  # Lean Ed Gillespie
      5  # Support/vote Cliff Hyra
      6  # Lean Cliff Hyra
      7  # Other, Undecided, Dont know/Refused

Chance to consider voting for other candidate:
  -- qchance_rep <- Chance to consider voting for republican
     Masterquestion:GOV_VOTE_CHANCE_REP. Q8 in GSG-Q.
     Is there a chance you might consider voting for Republican Ed Gillespie,
     or would you say there is NO chance you would consider voting for him?
  -- qchance_dem <- Chance to consider voting for democrat
     Masterquestion:GOV_VOTE_CHANCE_DEM. Q7 in GSG-Q.
     Is there a chance you might consider voting for Democrat Ralph Northam,
     or would you say there is NO chance you would consider voting for him?
     1. Chance might consider Northam/Gillespie
     2. NO chance would consider Northam/Gillespie
     3. Don’t know/Refused

   -- qcommit <- Support Commitment. Masterquestion: GOV_COMMIT. Question Q9 in GSG-Q
      How committed are you to voting for (CANDIDATE NAME)?

      1  # Absolutely committed
      2  # Somewhat committed
      3  # Not at all committed
      4  # Dont know/Not sure/Refused

Party direction:

   -- qpartydirection_dem <- Masterquestion: DEM_DIRECTION. Question 10 in GSG-Q
      Thinking about the Democratic Party as a whole, would you say that it is moving
      closer to your political views, farther away from your political views, or not
      really changing?
   -- qpartydirection_rep <- Masterquestion: REP_DIRECTION. Question 11 in GSG-Q
      Thinking about the Republican Party as a whole, would you say that it is moving
      closer to your political views, farther away from your political views, or not
      really changing?
      1  # Closer to your political views
      2  # Farther away from your views
      3  # Not really changing
      4  # Undecided/Refused/Dont know

    -- qfriends <- Masterquestion: FAMILY_VOTE_INTENT. Question 12 in GSG-Q
       Regardless of who you are supporting for various offices, as far as you know, are most
       of your friends and family voting mostly for Democrats, mostly for Republicans, or do
       they split their ticket depending on the office?
      1  # Mostly Democrats
      2  # Mostly Republicans
      3  # Split their tickets
      4  # Undecided, Refused, Dont know, Mostly other party
    -- self_ideology <- Masterquestion: IDEO. Question D105 in GSG-Q
      When it comes to politics, do you generally think of yourself as:
      1.Very liberal
      2.Somewhat liberal
      3.Moderate
      4.Somewhat conservative
      5.Very conservative
      6.Don’t know/Refused

Ideology of candidates: Masterquestions: GOV_IDEO_DEM/GOV_IDEO_REP. Questions 17-18 in GSG-Q
  -- dem_ideology <- When it comes to (DEM_CANDIDATE), do you generally think of him as:
  -- rep_ideology <- When it comes to (REP_CANDIDATE), do you generally think of him as:
     1.Very liberal
     2.Somewhat liberal
     3.Moderate
     4.Somewhat conservative
     5.Very conservative
     6.Don’t know/Refused
  -- qinterviewer <- Interviewer. Masterquestion: INT_EVAL_GOV. Question X1END in GSG-Q
     Evaluating the conversation you just had – How strong do you believe the respondent’s
     commitment is to voting for their final stated preferred candidate for Governor?
     1   Very strong
     2   Somewhat strong
   (3,4) Less than somewhat strong (Not that strong, Indifferent, Not strong at all)
   NA   # Don’t know / Refused - Enter NA if not included in survey

  -- generic_party_ballot<- electoral preference. Masterquestion: GOV_VOTE_2WAY_G.
     Question 2 in GSG-Q
     If  an  election  for  Governor  were  today,  would  you  vote  for  the
     Democratic  candidate  or  the  Republican candidate? (IF NOT SURE) But if
     you had to choose based only on each candidate’s party, which way would you lean?
     1. Democrat
     2. Lean Democrat
     3. Republican
     4. Lean Republican
     5. Undecided/Refused
''' */
                           -- CODE STARTS HERE--

-- First, we get the pre_survey masterquestions for 2016
--MQs_DGA_2016 is the reshaped table containing the pre_survey masterquestions for 2016
-- Reshape the table to have a single row for each personid

DROP TABLE IF EXISTS dga.MQs_DGA_2016;
CREATE TABLE dga.MQs_DGA_2016 AS (SELECT date, personid, voterbaseid  AS vb_voterbase_id,
                              MAX(CASE WHEN masterquestion = 'VOTE_LIKELIHOOD' THEN master_response
                              ELSE NULL END) as likelihood_vote,
                              MAX(CASE WHEN masterquestion = 'PARTY_1' THEN
                              master_response ELSE NULL END) as qparty,
                              MAX(CASE WHEN masterquestion = 'PARTY_2' THEN
                              master_response ELSE NULL END) as close_to_Party_ID,
                              MAX(CASE WHEN masterquestion = 'FAV_DEM' THEN
                              master_response ELSE NULL END) as dem_favorability,
                              MAX(CASE WHEN  masterquestion = 'FAV_REP' THEN
                              master_response ELSE NULL END) as rep_favorability,
                              MAX(CASE WHEN  masterquestion = 'GOV_VOTE' THEN
                              master_response ELSE NULL END) as qvote,
                              MAX(CASE WHEN  masterquestion = 'GOV_VOTE_CHANCE_REP' THEN
                              master_response ELSE NULL END) as qchance_rep,
                              MAX(CASE WHEN  masterquestion = 'GOV_VOTE_CHANCE_DEM' THEN
                              master_response ELSE NULL END) as qchance_dem,
                              MAX(CASE WHEN  masterquestion = 'GOV_COMMIT' THEN
                              master_response ELSE NULL END) as qcommit,
                              MAX(CASE WHEN  masterquestion = 'DEM_DIRECTION' THEN
                              master_response ELSE NULL END) as qpartydirection_dem,
                              MAX(CASE WHEN  masterquestion = 'REP_DIRECTION' THEN
                              master_response ELSE NULL END) as qpartydirection_rep,
                              MAX(CASE WHEN  masterquestion = 'FAMILY_VOTE_INTENT' THEN
                              master_response ELSE NULL END) as qfriends,
                              MAX(CASE WHEN  masterquestion = 'IDEO' THEN
                              master_response  ELSE NULL END) as self_ideology,
                              MAX(CASE WHEN masterquestion = 'GOV_IDEO_DEM' THEN
                              master_response ELSE NULL END) as dem_ideology,
                              MAX(CASE WHEN masterquestion = 'GOV_IDEO_REP' THEN
                              master_response ELSE NULL END) as rep_ideology,
                              MAX(CASE WHEN masterquestion ='INT_EVAL_GOV' THEN
                              master_response  ELSE NULL END) AS qinterviewer,
                              MAX(CASE WHEN masterquestion = 'GOV_VOTE_2WAY_G' THEN
                              master_response ELSE NULL END) AS generic_party_ballot,
                              MAX(CASE -- This is the relevant recode for pre_survey 2017 dependent variable
                                WHEN masterquestion = 'GOV_VOTE' AND (master_response = 1 or master_response = 2) THEN 'DEM'
                                WHEN masterquestion = 'GOV_VOTE' AND (master_response = 3 or master_response = 4)  THEN 'REP'
                                WHEN masterquestion = 'GOV_VOTE' AND (master_response = 5 or master_response = 6 or master_response = 7
                                or master_response = 8 or master_response = 9 or master_response = 10) THEN 'IND'
                                WHEN masterquestion = 'GOV_VOTE' AND (master_response = 97) THEN 'OTHER'
                                WHEN masterquestion = 'GOV_VOTE' AND (master_response = 99) THEN 'DK/UND/REF'
                                ELSE NULL END) AS pre_gov_vote

                             FROM (SELECT
                                  d.personid,
                                  d.voterbaseid,
                                  d.typecode,
                                  d.phone,
                                  d.date,
                                  d.questionid,
                                  q.masterquestion,
                                  d.response,
                                  r.master_response
                                  FROM ( dga.dga_pre_survey_resp d
                                         left JOIN dga.dga_master_resp r ON
                                         d.response = r.response_id AND d.typecode = r.typecode
                                                                    AND d.questionid = r.questionid
                                         left JOIN dga.dga_master_qts q ON d.typecode = q.typecode
                                                                    AND d.questionid = q.questionid))
                                        AS SourceTable GROUP BY personid, date, voterbaseid);
ALTER TABLE dga.MQs_DGA_2016
ADD year INT;
UPDATE dga.MQs_DGA_2016
SET year = 2016;

-- Create table dga.MQs2016 that will stack with the 2017 table.

DROP TABLE IF EXISTS dga.MQs2016;
CREATE TABLE dga.MQs2016 (date VARCHAR (255),
                      personid INT,
                      vb_voterbase_id VARCHAR(255),
                      weight FLOAT ,
                      person_id_type VARCHAR (255),
                      schema_name VARCHAR (255),
                      table_name VARCHAR(255),
                      survey_id VARCHAR (255),
                      state_code VARCHAR(255),
                      firm VARCHAR(255),
                      length_minutes INT,
                      switcher_score FLOAT,
                      switcher_flag VARCHAR(255),
                      excitement_to_vote VARCHAR(255),
                      qchance_combined VARCHAR(255),
                      qpartydirection_combined VARCHAR(255),
                      work_environment VARCHAR(255),
                      likelihood_vote INT,
                      qparty INT,
                      close_to_party_ID VARCHAR (255),
                      dem_favorability VARCHAR (255),
                      rep_favorability VARCHAR (255),
                      qvote INT,
                      qchance_rep INT,
                      qchance_dem INT,
                      qcommit INT,
                      qpartydirection_dem INT,
                      qpartydirection_rep INT,
                      qfriends INT,
                      self_ideology VARCHAR (255),
                      dem_ideology VARCHAR (255),
                      rep_ideology VARCHAR (255),
                      qinterviewer INT,
                      generic_party_ballot VARCHAR (255),
                      pre_gov_vote VARCHAR(255),
                      year  INT );

-- Populate MQs2016 with the masterresponses from MQs_DGA_2016:

INSERT INTO dga.MQs2016 ( date ,personid , vb_voterbase_id , likelihood_vote , qparty ,
  close_to_Party_ID, dem_favorability , rep_favorability, qvote ,qchance_rep ,qchance_dem ,
  qcommit ,qpartydirection_dem ,qpartydirection_rep ,qfriends ,self_ideology ,
  dem_ideology ,rep_ideology ,qinterviewer , generic_party_ballot , pre_gov_vote, year  )
SELECT date, personid, vb_voterbase_id, likelihood_vote, qparty,
close_to_Party_ID, dem_favorability,rep_favorability, qvote,qchance_rep,qchance_dem,
qcommit,qpartydirection_dem, qpartydirection_rep,qfriends,self_ideology,
dem_ideology,rep_ideology, qinterviewer,  generic_party_ballot , pre_gov_vote, year

FROM dga.MQs_DGA_2016;

-- Repeat the steps for 2017. In this case, we use the GSG scripts, not the masterquestions/master_responses

DROP TABLE IF EXISTS dga.MQs_DGA_2017;
CREATE TABLE dga.MQs_DGA_2017 AS (SELECT s.personid::INT,
                                     s.tsmtvoterbaseid AS vb_voterbase_id,
                                     s.weight ,
                                     s.person_id_type ,
                                     s.schema_name ,
                                     s.table_name,
                                     s.survey_id ,
                                     s.start_date AS date,
                                     s.state_code ,
                                     s.firm ,
                                     s.length_minutes ,
                                     s.qvote ,
                                     s.qcommit ,
                                     s.qchance_combined ,
                                     s.qchance_dem ,
                                     s.qchance_rep ,
                                     s.qfriends ,
                                     s.qparty ,
                                     s.qpartydirection_combined ,
                                     s.qpartydirection_dem ,
                                     s.qpartydirection_rep ,
                                     s.qinterviewer ,
                                     s.switcher_score ,
                                     s.switcher_flag ,
                                     m.s2 AS likelihood_vote,
                                     m.p1y AS close_to_Party_ID ,
                                     m.q1  AS excitement_to_vote,
                                     m.q2 generic_party_ballot,
                                     m.q5 AS dem_favorability,
                                     m.q6  AS rep_favorability ,
                                     m.D105  AS self_ideology ,
                                     m.q17 AS dem_ideology ,
                                     m.q18  AS rep_ideology ,
                                     m.d129  AS work_environment,
                                     (CASE     -- Here is the code for the dependent variable, pre_survey 2017:
                                       WHEN qvote = 1 or qvote = 2 THEN 'DEM'
                                       WHEN qvote = 3 or qvote = 4 THEN 'REP'
                                       WHEN  qvote = 5 or qvote = 6  THEN 'IND'
                                       WHEN  qvote = 7  THEN 'DK/UND/REF'
                                       ELSE NULL END) AS pre_gov_vote
                                FROM switcher.master_switch_data  s left join dga.va_mm_stacked_waves  m
                                ON s.personid = m.personid
                                AND  s.start_date = m.survey_date);
-- Add the year
  ALTER TABLE dga.MQs_DGA_2017
  ADD year INT;
  UPDATE dga.MQs_DGA_2017
  SET year = 2017;

  DROP TABLE IF EXISTS dga.MQs2017;
  CREATE TABLE dga.MQs2017 (
      date VARCHAR (255),
      personid INT,
      vb_voterbase_id VARCHAR(255),
      weight FLOAT ,
      person_id_type VARCHAR (255),
      schema_name VARCHAR (255),
      table_name VARCHAR(255),
      survey_id VARCHAR (255),
      state_code VARCHAR(255),
      firm VARCHAR(255),
      length_minutes INT,
      switcher_score FLOAT,
      switcher_flag VARCHAR(255),
      excitement_to_vote VARCHAR(255),
      qchance_combined VARCHAR(255),
      qpartydirection_combined VARCHAR(255),
      work_environment VARCHAR(255),
      likelihood_vote INT,
      qparty INT,
      close_to_Party_ID VARCHAR (255),
      dem_favorability VARCHAR (255),
      rep_favorability VARCHAR (255),
      qvote INT,
      qchance_rep INT,
      qchance_dem INT,
      qcommit INT,
      qpartydirection_dem INT,
      qpartydirection_rep INT,
      qfriends INT,
      self_ideology VARCHAR (255),
      dem_ideology VARCHAR (255),
      rep_ideology VARCHAR (255),
      qinterviewer INT,
      generic_party_ballot VARCHAR (255),
      pre_gov_vote VARCHAR (255),
      year  INT );
-- Populate 2017 table with masterquestions/master_responses

  INSERT INTO dga.MQs2017 (date, personid, vb_voterbase_id, weight, person_id_type,
    schema_name, table_name, survey_id, state_code, firm, length_minutes,
    switcher_score, switcher_flag, excitement_to_vote, qchance_combined,
    qpartydirection_combined, work_environment, likelihood_vote, qparty,
    close_to_Party_ID, dem_favorability, rep_favorability, qvote, qchance_rep,
    qchance_dem, qcommit, qpartydirection_dem, qpartydirection_rep, qfriends,
    self_ideology, dem_ideology, rep_ideology, qinterviewer, generic_party_ballot, pre_gov_vote, year )
   SELECT date, CAST(personid as INT), vb_voterbase_id , weight,  person_id_type,
   schema_name, table_name, survey_id, state_code, firm, length_minutes,
   switcher_score, switcher_flag, excitement_to_vote, qchance_combined,
   qpartydirection_combined, work_environment, likelihood_vote, qparty,
   close_to_Party_ID, dem_favorability, rep_favorability,  qvote, qchance_rep,
   qchance_dem,  qcommit,  qpartydirection_dem, qpartydirection_rep, qfriends,
   self_ideology, dem_ideology, rep_ideology,   qinterviewer,  generic_party_ballot , pre_gov_vote, year
   FROM dga.MQs_DGA_2017;


DROP TABLE IF EXISTS dga.DGA_switcher2016_2017;
CREATE TABLE dga.DGA_switcher2016_2017 AS (SELECT * FROM  dga.MQs2017 UNION (SELECT * FROM dga.MQs2016));
