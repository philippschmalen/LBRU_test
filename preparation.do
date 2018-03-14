clear *
cap log close
set more off, permanently

/* FILE STRUCTURE IN DIRECTORY

		1	Dofiles
		2	Logfiles
		3	Raw		-- Raw data located here! Save in Data folder
		4	Tables
		5	Graphs, Figures
		6	Data
*/

cd "C:\Users\Philipp\GDrive\VWL\NEPS Dropout\Data_SC3"
cap log using Logfiles\preparation_sc3_7-0-0.txt, text replace
use Data\foundation


******************************* DATA PREPARATION *******************************
*------------------------------------------------------------------
*	Student Gender
*------------------------------------------------------------------

g male1 = .
	replace male1 = 1 if tx80501 == 1
	replace male1 = 0 if tx80501 == 2
	la var male1 "Gender as specified in class list"

g male2 = .
	replace male2 = 1 if t700031 == 1
	replace male2 = 0 if t700031 == 2
	la var male2 "Gender as reported by student"

g male3 = .
	replace male3 = 1 if p700010 == 1
	replace male3 = 0 if p700010 == 2
	la var male3 "Gender as reported by parent"

*Consistency check for gender variable 
g gender_check = 0

foreach i of numlist 2/3 {
	replace gender_check = 1 if male`i' != male1 & male`i' < . & male1 < .
	replace gender_check = 1 if male`i' != male2 & male`i' < . & male2 < .
}

*Count nomissings over male*
egen n_help = rownonmiss(male*) if gender_check == 1
egen male_help = rowtotal(male*) if gender_check == 1, missing 
g ratio_help = male_help/n_help
g gender_warning = 1 if ratio_help == 0.5


g male = .
foreach i of numlist 1/3 {
	replace male = male`i' if male`i' < . & gender_check == 0
}

replace male = 1 if ratio_help > 0.5 & ratio_help < .
replace male = 0 if ratio_help < 0.5 & ratio_help < .

*Take report by parents or if not available by class list
replace male = male3 if male3 < . & gender_warning == 1
replace male = male1 if male1 < . & gender_warning == 1

bys ID_t (wave): replace male = male[_n-1] if male[_n] == . //Make available through all waves
bys ID_t (wave): g xcheck = (male[_n] != male[_n-1] & wave > 1) //check for changes of gender over waves
	bys ID_t (wave): replace xcheck = xcheck[_n-1] if xcheck[_n-1] == 1 & xcheck[_n] != 1
	bys ID_t (wave): replace xcheck = xcheck[7] //make xcheck indicator for all waves
//bys ID_t (wave): egen coug1 = count(male4) if male4 == 1 & xcheck == 1 
//bys ID_t (wave): egen coug0 = count(male4) if male4 == 0 & xcheck == 1 
	//replace male = 1 if coug1 > 1 & coug1 < . 
	//replace male = 0 if coug0 > 1 & coug0 < .

drop xcheck

bys ID_t (wave): g xcheck = (male[_n] != male[_n-1] & wave > 1) //check for changes of gender over waves
	bys ID_t (wave): replace xcheck = xcheck[_n-1] if xcheck[_n-1] == 1 & xcheck[_n] != 1
	bys ID_t (wave): replace xcheck = xcheck[7] //make xcheck indicator for all waves


la var male "male"

drop n_help male_help ratio_help gender_warning gender_check male1-male3 xcheck //coug*





*------------------------------------------------------------------
*	Panel Information
*------------------------------------------------------------------
**** Attrition ****
*How many surveyed in wave 1 are found in wave 6?
g avail_w1 = 1 if tx80522 == 1 & wave == 3
	replace avail_w1 = 0 if tx80521 == 0 & wave == 1
	bys ID_t (wave): replace avail_w1 = avail_w1[1] 
	
g avail_w2 = 1 if tx80521 == 1 & wave == 7
	replace avail_w7 = 0 if tx80521 == 0 & wave == 7
	bys ID_t (wave): replace avail_w7 = avail_w7[7] 

g avail_full = 1 if avail_w1 == 1 & avail_w7 == 1

*Parents survey available?
g parents_avail = 1 if tx80523 == 1
	replace parents_avail = 0 if tx80523 == 0
	bys ID_t (wave): replace parents_avail = parents_avail[1]

*Time of first interview
g first_survey_wave = tx80107
	la var first_survey_wave "Wave when the first survey took place"

*panel frame
g panel_frame = tx80230 if tx80230 > 0
	la val panel_frame de2569 
	
*sampling edutype
g sampling_edu = tx80106 
	drop if sampling_edu == 7 //drop special needs school 
	
*institution ID
g institution = ID_i





*------------------------------------------------------------------
*	School information
*------------------------------------------------------------------


******** Edutype ********
bys ID_t (wave): g edutype = 1 if t723080_g1 == 3 | t723080_g1 == 6 | t723080_g1 == 12 //HS
	bys ID_t (wave): replace edutype = -1 if t723080_g1 == 1 | t723080_g1 == 2 //Elem or orientation 
	bys ID_t (wave): replace edutype = 2 if t723080_g1 == 4 | t723080_g1 == 7 | t723080_g1 == 13 //RS
	bys ID_t (wave): replace edutype = 3 if t723080_g1 == 5 | t723080_g1 == 8 | t723080_g1 == 11 | t723080_g1 == 15 //GS and other
	bys ID_t (wave): replace edutype = 4 if t723080_g1 == 9 | t723080_g1 == 14 //GY
	bys ID_t (wave): replace edutype = 0 if t723080_g1 == - 55 //OUT: not determinable
	la de edutype_la -2 "VOC" -1 "ORI" 0 "OUT" 1 "HS" 2 "RS" 3 "GS" 4 "GY" 
	la val edutype edutype_la 
	*info from individual tracking
	g tracked_edutype = -1 if tx80232 == 1 | tx80232 == 2 //elem. school or orientation
		replace tracked_edutype = 1 if tx80232 == 4 //HS
		replace tracked_edutype = 2 if tx80232 == 5 | tx80232 == 6 //RS
		replace tracked_edutype = 3 if tx80232 == 3 //GS
		replace tracked_edutype = 4 if tx80232 == 7 //GY
	replace edutype = tracked_edutype if tracked_edutype != . & edutype == . //take tracking info if regular edutype is missing
	*info from panel_frame (3: vocational)
	replace edutype = -2 if panel_frame == 3 & edutype == . //VOC
	*info from first sampling edutype
	replace edutype = -1 if sampling_edu == 1 & wave == 1 //Orientation/Elementary
	replace edutype = 1 if sampling_edu == 2 & wave == 1 //HS
	replace edutype = 2 if sampling_edu == 3 | sampling_edu == 4 & wave == 1 //RS
	replace edutype = 3 if sampling_edu == 5 & wave == 1 //GS
	replace edutype = 4 if sampling_edu == 6 & wave == 1 //GY
	*assume dropout if missing
	bys ID_t (wave): replace edutype = 0 if edutype == . //OUT if missing

	
bys ID_t (wave): g gym = 1 if edutype[1] == 4 & edutype != 0
	bys ID_t (wave): replace gym = 0 if edutype != 4

	

******** Dropout ********
*Dropout GY for those available
bys ID_t (wave): g gym_dropout = 0 if gym[1] == 1
	bys ID_t (wave): replace gym_dropout = 1 if gym[7] != 1 & gym_dropout == 0 

/* 	*Availability of parent info for dropouts
	ta parents_avail if dropout == 1 & wave == 1 //21.8% dropouts have no parental info! 
	ta parents_avail if dropout == 0 & wave == 1 //21.17% of non-dropouts do not have
	ttest parents_avail if wave == 1, by(dropout) //difference not significant
	ttest dropout_std if wave == 1, by(male) //7pp/16% SD more dropout of males from GYM */

*Dropout Timing
bys ID_t (wave): g dropout_timing = 0 if edutype[1] == 4  //from the first wave
	bys ID_t (wave): replace dropout_timing = 0 if edutype[3] == 4 
	bys ID_t (wave): replace dropout_timing = 1 if edutype[_n+1] != 4 & dropout_timing == 0
	bys ID_t (wave): replace dropout_timing = 0 if dropout_timing[_n+1] == 1 & dropout_timing[_n-1] == 0 
	replace dropout_timing = . if wave == 7

	
*College Track Dropout
bys ID_t (wave): g ctrack_dropout_nomiss = 0 if edutype[7] == 4 //at GY in last wave - no dropout
	bys ID_t (wave): replace ctrack_dropout_nomiss = 1 if edutype[7] != 4 & edutype[7] != . //not at GY in 5th grade, no missings
g ctrack_dropout_allmiss = ctrack_dropout_nomiss
	bys ID_t (wave): replace ctrack_dropout_allmiss = 1 if edutype[7] != 4 //incl all missings in wave 7
g ctrack_dropout_diff = 1 if ctrack_dropout_allmiss != . & ctrack_dropout_nomiss == . //identify missing, differing values
	replace ctrack_dropout_diff = 0 if ctrack_dropout_nomiss != . & ctrack_dropout_allmiss != .
bys ID_t (wave): g ctrack_dropout_accum = 0 if edutype[7] != . 
	bys ID_t (wave): replace ctrack_dropout_accum = 1 if edutype[7] != 4 & ctrack_dropout_accum[7] == .


******** Risers ********
*Educational rise to GYM
bys ID_t (wave): g edu_rise = 0 if edutype[1] != 4 
	bys ID_t (wave): replace edu_rise = 1 if (edutype == 4 | edu_rise[_n-1] == 1) & (edu_rise != .)
	bys ID_t (wave): replace edu_rise = 1 if edu_rise[7] == 1


******** Movers ********
*Track-mover definition: You have been in a different school track in the previous wave
bys ID_t (wave): g track_mover = 0 if edutype[_n] != . & edutype[_n-1] != . //condition: information available on edu in a wave
	bys ID_t (wave): replace track_mover = 1 if edutype[_n] != edutype[_n-1] & /// //'lagged' track_mover, referring to the previous wave
		track_mover == 0
		
	//cou if track_mover == 1 & male == 0 //almost equal number of males/females
	


**** Grade Repetition/Skipping ****
*from parents questionaire: p725000
g grade_repeated = 1 if t725020 == 2 & wave == 1
	replace grade_repeated = 0 if t725020 == 1 & wave == 1
	//ttest grade_repeated if wave == 1, by(male) //4pp more male

*skipped
g grades_skipped = 1 if p726000 == 1
	replace grades_skipped = 0 if p726000 == 2
	bys ID_t (wave): replace grades_skipped = 1 if grades_skipped[_n-1] == 1
	bys ID_t (wave): replace grades_skipped = 1 if grades_skipped[7] == 1
	bys ID_t (wave): replace grades_skipped = grades_skipped[1]







*------------------------------------------------------------------
*	Student 
*------------------------------------------------------------------


************ Age ************ 

g month_list = tx8050m if tx8050m > 0 //as specified in class list 
g year_list = tx8050y if tx8050y > 0

g month_pquest = p70012m if p70012m > 0  //as in parental questionnaire
g year_pquest =  p70012y if p70012y > 0

g month_stud = t70004m if t70004m > 0 //student questionnaire
g year_stud = t70004y if t70004y > 0 

*Parents info > class list > self reported by student
g birth_month = month_pquest 
	replace birth_month = month_list if birth_month == .
	replace birth_month	= month_stud if birth_month == .

g birth_year = year_pquest
	replace birth_year = year_list if birth_year == .
	replace birth_year = year_stud if birth_year == .

g age = .
local x = 1
forv i = 2010/2016 { 	
	replace age = `i' - birth_year if wave == `x' & birth_year != .
	local x = 1 + `x'
}

//assume all interviews done in january
replace age = age + (birth_month/12) if birth_month != . & age != .
	egen age_std = std(age)
	g age_squared = age*age
	egen age_squared_std = std(age_squared)

drop month_list year_list *_pquest month_stud year_stud


************ Migrant Status ************ 
*Not born in GER and moved here 
g migrant = 1 if t400030 >= 0
	replace migrant = 0 if t400030 < 0 //year of moving to GER
	replace migrant = 1 if p406000 == 2 & migrant == 0 | migrant == . //child born outside of GER
	replace migrant = 0 if p406000 == 1 & migrant == .
	replace migrant = 1 if t400070_g1D == 1 & (migrant == . | migrant == 0) //mother born outside GER
	replace migrant = 0 if t400070_g1D == 0 & migrant == .
	replace migrant = 1 if t400090_g1D == 1 & (migrant == . | migrant == 0) //father born outside GER
	replace migrant = 0 if t400090_g1D == 0 & migrant == .


**** School attitude of peers ****
*Do your peers care about school?
g attitude_school_indifferent = t32112b if t32112b > 0
bys ID_t (wave): replace attitude_school_indifferent = attitude_school_indifferent[_n-1] ///
	if attitude_school_indifferent[_n] == . & attitude_school_indifferent[_n-1] != .
	bys ID_t (wave): replace attitude_school_indifferent = attitude_school_indifferent[2] //shift observations into 1st wave
	

*School absence: Okay or not?
g absent_opinion = t518120 if t518120 > 0






**** Aspiration ****
*t31035a - idealistic; t31135a - realistic
g aspiration_ideal = t31035a if t31035a > 0 //available for wave 1-3
	replace aspiration_ideal = 0 if aspiration_ideal == 4
	egen aspiration_ideal_std = std(aspiration_ideal)
*Change over time: Ideal Aspirations
bys ID_t (wave): g aspiration_ideal_dyn = aspiration_ideal[3] - aspiration_ideal[1] 
	egen aspiration_ideal_dyn_std = std(aspiration_ideal_dyn)

g aspiration_real = t31135a if t31135a > 0 
	replace aspiration_real = 0 if aspiration_real == 4
	egen aspiration_real_std = std(aspiration_real) 
	
*Change over time: Real Aspirations
bys ID_t (wave): g aspiration_real_dyn = aspiration_real[3] - aspiration_real[1] 
	egen aspiration_real_dyn_std = std(aspiration_real_dyn)


	
**** Attitudes towards Education *****
*s.t. higher values indicate pro-education attitude; surveyed in wave 3
	g att_h1 = 6-t31300d if t31300d > 0 //Zeitverschwendung
	g att_h2 = t31300l if t31300l > 0 //Abitur um jeden Preis
	g att_h3 = t31300k if t31300k > 0 //Shame if no Abi
	g att_h4 = 6-t31300h if t31300h > 0 //become arrogant
	g att_h5 = t31300e if t31300e > 0 //widens horizon
	g att_h6 = t31300f if t31300f > 0 //high edu good for culture
egen edu_attitude = rowmean(att_h1)
egen edu_attitude_std = std(edu_attitude)
	bys ID_t (wave): replace edu_attitude_std = edu_attitude_std[3] //make information available in all waves 

drop att_h*

**** Time for Homework ****
g homework_time = t281600 if wave == 1 & t281600 > 0


**** Missing days at school ****
g missing_schooldays = t523010 if wave == 1 & t523010 >= 0 
	replace missing_schooldays = 0 if t523010 < -54

	
g missing_exaggerated = 1 if wave == 1 & t523010 > 20
	replace missing_exaggerated = 0 if wave == 1 & t523010 < 21

**** Self-concept at School **** 
g german_selfconcept = t66000a_g1 if wave == 1 & t66000a_g1 > 0 //e.g. Im Fach Deutsch bin ich ein hoffnungsloser Fall.
	egen german_selfconcept_std = std(german_selfconcept)
g math_selfconcept = t66001a_g1 if wave == 1 & t66001a_g1 > 0 //e.g Im Fach Mathematik bekomme ich gute Noten.
	egen math_selfconcept_std = std(math_selfconcept)
g school_selfconcept = t66002a_g1 if wave == 1 & t66002a_g1 > 0 //e.g. In den meisten Faechern schneide ich gut ab.
	egen school_selfconcept_std = std(school_selfconcept)

**** German Teacher Perceptions ****
*Deutschlehrer: traut mir bessere Leistung zu
g ger_teacher_perception = td0033b if wave == 1 & td0033b > 0
	ttest ger_teacher_perception if wave == 1, by(male)



**** Grades ****
*Grades t724101 German, t724102 Math 
g grade_ger =  t724101 if t724101 > 0
g grade_mat = t724102 if t724102 > 0 
egen grade_avg = rowmean(grade_ger grade_mat)

*Standardize in first wave
foreach x of varlist grade_ger grade_mat {
	egen `x'_std = std(`x') if wave == 1
}

foreach x of varlist grade_*_std {
	ttest `x' if wave == 1, by(male)
}

*Deviate upwards once with gpa
bys ID_t (wave): g up_grade = 0 if grade_avg[_n] == grade_avg[_n-1] & grade_avg[_n-1] != . & grade_avg[_n] != .  
	bys ID_t (wave): replace up_grade = 1 if grade_avg[_n] < grade_avg[_n-1] & grade_avg[_n-1] != . & grade_avg[_n] != .




**** Reading ****
*Amount per day; wave 1-5 available
g read_schoolday = t34001a if t34001a > 0 //school day
	egen read_schoolday_std = std(read_schoolday) if wave == 1
g read_otherday =   t34001c if t34001c > 0 //other days
	egen read_otherday_std = std(read_otherday) if wave == 1
g read_total = read_schoolday + read_otherday
	egen read_total_std = std(read_total)
drop read_school* read_other* read_total*
	
*Attitudes towards reading
//construct score of positive attitudes towards reading 
local i = 1
foreach x of varlist td0042a-td0042f { //get rid of missings 
	g read_att`i' = `x' if `x' > 0
	local i = `i' + 1
}
egen read_attitudes = rowmean(read_att1-read_att6)


**** Big Five ****
*Only wave 3 and 4
/* t66800b_g1 //A
t66800e_g1 //O
t66800d_g1 //N
t66800c_g1 //C
t66800a_g1 //E */


**** Self-esteem ****
g self_esteem = t66003a_g1 if t66003a_g1 > 0
	egen self_esteem_std = std(self_esteem)





*-----------
*	Competence tests/C-skills
*-----------
g cskills_speed_g5 = dgg5_sc3a if dgg5_sc3a > 0 & wave == 1 //perceptual speed 5th grade
g cskills_speed_g9 = dgg9_sc3a if dgg9_sc3a > 0 & wave == 5 

g cskills_reason_g5 = dgg5_sc3b if dgg5_sc3b >= 0 & wave == 1 //reasoning 5th grade
g cskills_reason_g9 = dgg9_sc3b if dgg9_sc3b >= 0 & wave == 5

g cskills_math_g5 = mag5_sc1u if mag5_sc1u > -56 & wave == 1 //math skills 5th grade
g cskills_math_g7 = mag7_sc1u if mag7_sc1u > -56 & wave == 3
g cskills_math_g9 = mag9_sc1u if mag9_sc1u > -56 & wave == 5

g cskills_read_g5 = reg5_sc1u if reg5_sc1u > -56 & wave == 1 //reading skills 5th grade
g cskills_read_g7 = reg7_sc1u if reg7_sc1u > -56 & wave == 3
g cskills_read_g9 = reg9_sc1u if reg9_sc1u > -56 & wave == 5
	bys ID_t (wave): g cskills_read = cskills_read_g5
		bys ID_t (wave): replace cskills_read = cskills_read_g7 if cskills_read == .
		bys ID_t (wave): replace cskills_read = cskills_read_g9 if cskills_read == .


foreach x of varlist cskills_*_g5 {
	egen `x'_std = std(`x') if wave == 1
}
foreach x of varlist cskills_*_g7 {
	egen `x'_std = std(`x') if wave == 3
}
foreach x of varlist cskills_*_g9 {
	egen `x'_std = std(`x') if wave == 5
}

la var cskills_speed_g5_std "Preceptual Speed"
la var cskills_speed_g9_std "Preceptual Speed"
la var cskills_reason_g5_std "Reasoning"
la var cskills_reason_g9_std "Reasoning"
la var cskills_math_g5_std "Math Competence"
la var cskills_math_g7_std "Math Competence"
la var cskills_math_g9_std "Math Competence"
la var cskills_read_g5_std "Reading Competence"
la var cskills_read_g7_std "Reading Competence"
la var cskills_read_g9_std "Reading Competence"


*-----------
*	HH Status
*-----------
**** Reported by student ****
*mother living in HH
g hh_motherpresent = 1 if t74305a == 1
	replace hh_motherpresent = 0 if t74305a == 2  
*stepmother/girlfriend in HH
g hh_stepmom = 1 if t74305b == 1
	replace hh_stepmom = 0 if t74305b == 2
*father living in hh
g hh_fatherpresent = 1 if t74305c == 1
	replace hh_fatherpresent = 0 if t74305c == 2
*stepdad/boyfriend in HH
g hh_stepdad = 1 if t74305d == 1
	replace hh_stepdad = 0 if t74305d == 2
*grandparents
g hh_grandparents = 1 if t74305f == 1
	replace hh_grandparents = 0 if t74305f == 2
*other persons
g hh_otherpresent = 1 if t74305g == 1
	replace hh_otherpresent = 0 if t74305g == 2
*mother 
g bio_mother = 1 if t731130 == 1
	replace bio_mother = 0 if t731130 != 1 & t731130 > 0
*father
g bio_father = 1 if t731140 == 1
	replace bio_father = 0 if t731140 != 1 & t731140 > 0


**** Siblings in HH ****
g number_siblings = p732103 if p732103 >= 0
g number_hh_siblings = p732104 if p732104 >= 0

g hh_siblingspresent = 1 if t74305e == 1
	replace hh_siblingspresent = 0 if t74305e == 2
	replace hh_siblingspresent = 1 if number_hh_siblings > 0 & number_hh_siblings != .
	replace hh_siblingspresent = 0 if number_hh_siblings == 0



**** HH size ****
g hh_size = p741001 if p741001 > 0 //by parents; outlier: 1 - 40
	replace hh_size = t741002 if t741002 > 0 & hh_size == . //reported by student
	egen hh_size_std = std(hh_size)



**** HH income //what is not yet used: HH income coarse split-info ****
g hh_income = p510001 if p510001 > 0 //open question
	replace hh_income = p510005 if p510005 > 0 & hh_income == . //open question other waves

	local x = 750
	forv i = 1/7 { //for split income <2500
		replace hh_income = `x' if hh_income == . & (p510003 == `i' | p510004 == `i' ) 
		local x = `x' + 500
	}
	replace hh_income = 11000 if p510004 == 8 & hh_income == . //assume income of 11000 if category > 5000 (highest 1% of open question)

	local x = 750
	forv i = 1/8 {
		replace hh_income = `x' if (p510007 == `i' | p510008 == `i' | p510009 == `i') & hh_income == .
		local x = `x' + 500
	}
	replace hh_income = 11000 if p510009 == 9 & hh_income == . 




*-----------
*	Parents/SES
*-----------
*Assumed that respondent is mother
g edu_mother_years = p731802_g3 if p731802_g3 >= -20
g edu_mother = 0 if edu_mother_years == -20 //no degree
	replace edu_mother = 1 if edu_mother_years == 9 //HS
	replace edu_mother = 2 if edu_mother_years == 10 //RS
	replace edu_mother = 3 if edu_mother_years == 12 //FAbi
	replace edu_mother = 4 if edu_mother_years == 13 //Abi
	replace edu_mother = 5 if edu_mother_years == 15 //Some College
	replace edu_mother = 6 if edu_mother_years == 16 //BA
	replace edu_mother = 7 if edu_mother_years == 18 //Dipl./MA
	
g edu_father_years = p731852_g3 if p731852_g3 >= -20
g edu_father = 0 if edu_father_years == -20 //no degree
	replace edu_father = 1 if edu_father_years == 9 //HS
	replace edu_father = 2 if edu_father_years == 10 //RS
	replace edu_father = 3 if edu_father_years == 12 //FAbi
	replace edu_father = 4 if edu_father_years == 13 //Abi
	replace edu_father = 5 if edu_father_years == 15 //Some College
	replace edu_father = 6 if edu_father_years == 16 //BA
	replace edu_father = 7 if edu_father_years == 18 //Dipl./MA

foreach x of varlist edu_mother edu_father edu_*_years {
	egen `x'_std = std(`x')
}




**** Single Parent ****
g single_parent = 1 if (hh_motherpresent == 1 & hh_fatherpresent == 0) | (hh_motherpresent == 0 & hh_fatherpresent == 1)
	replace single_parent = 0 if hh_motherpresent == 1 & hh_fatherpresent == 1


**** Low SES ****
/*
i) eq_income < 1065 (30% quantile of income distr. acc. SOEP 2009) 
ii) neither parent has Abitur: education_respondent, education_partner, education_mother, education_father
omitted: iii) items for learning or other essential stuff is missing at home, indicated by homepos
iv) single parent household (either father or mother) */
g low_ses = 0 if single_parent != . | hh_income != . | edu_mother != . | edu_father != .
	replace low_ses = 1 if single_parent == 1 //if single parent
	replace low_ses = 1 if edu_mother <= 3 & edu_father<= 3 //low edu: no abitur
	replace low_ses = 1 if edu_mother <= 3 & edu_father == . //low edu: no abitur
	replace low_ses = 1 if edu_mother == . & edu_father<= 3 //low edu: no abitur
	replace low_ses = 1 if hh_income < 1065 


*--------------------
* Interaction terms
*--------------------
g malexlow_ses = low_ses * male
g malexselfesteem_std = self_esteem_std * male
g malexaspiration_std = aspiration_ideal_std * male

*------------------------------------------------------------------------------------------------------------
* Variables to keep in the dataset
*------------------------------------------------------------------------------------------------------------
global basic age_std age_squared_std migrant 
	//health_eval_std east_west  
global ses edu_*_years_std single_parent hh_siblingspresent hh_size low_ses malexlow_ses
	//grad_mother_std grad_father_std single_mother single_father hh_unknown
	//low_income_male gradm_male_std gradf_male_std child_parents_attitude_std family_sa_std
global c cskills_*_g5_std 
	//reasoning_std percept_speed_std reading_speed_std math_score_std 
	//vocabulary_score_std ict_score_std scientific_literacy_std reading_score_std  declarative_std (META)
global nc self_esteem_std malexselfesteem_std edu_attitude_std homework_time missing_schooldays german_selfconcept_std ///
		math_selfconcept_std school_selfconcept_std
	// sdq_* bf_* sensitivity_std illusion_std  sport_std 
global outcome ctrack_dropout_nomiss ctrack_dropout_allmiss ctrack_dropout_diff gym_dropout grade_repeated grade_*_std attitude_school_indifferent /// 
		grade_repeated grades_skipped aspiration_ideal_std malexaspiration_std edu_rise ctrack_dropout_accum dropout_timing
	//uncertain attrition_college_track
global weights //ID_i ID_t w_i stratum_exp w_t w_t1 w_t2 w_t12 w_t3 w_t123 w_t4 w_t1234 ///
	//w_t5 w_t1235 w_t6 w_t12356 w_t7 w_t12357 w_t8 w_t123578 w_t9 w_t1235789 w_t1_cal

global keeping edutype male avail_full parents_avail wave institution
global all $basic $ses $c $nc $outcome $weights $keeping 


keep $all



save Data\analysis, replace
	
