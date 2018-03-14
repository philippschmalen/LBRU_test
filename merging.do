clear *
cap log close
set more off, permanently

/* FILE STRUCTURE IN DIRECTORY

		1	Dofiles
		2	Logfiles
		3	Raw		-- Raw data located here!
		4	Tables
		5	Graphs
		6	Data
*/

cd "C:\Users\Philipp\GDrive\VWL\NEPS Dropout\Data_SC2"
cap log using Logfiles\merging_sc2_6-0-0.txt, text replace



******************************* MERGING *******************************
*Master-Files
use Raw\SC2_CohortProfile_D_6-0-0  //Data\foundation


*Target PAPI (main information) 
mer 1:m ID_t wave using Raw\SC2_pTarget_D_6-0-0
	duplicates tag ID_t wave, gen(dup_idt)
	drop if dup_idt 		//--- issue with duplicates at SC3
	drop dup_idt _merge 

*Target competence tests
mer m:1 ID_t using Raw\SC2_xTargetCompetencies_D_6-0-0, nogen

*Parents
mer 1:1 ID_t wave using Raw\SC2_pParent_D_6-0-0, nogen

*Parents methods
mer 1:1 ID_t wave using Raw\SC2_ParentMethods_D_6-0-0, nogen

*BRR Weights
*mer m:1 ID_t using Raw\SC2_Weights_D_6-0-0, nogen

save Data\foundation, replace




*Teacher Merge
clear * 
use Raw\SC2_pEducator_D_6-0-0 
	sort ID_e ID_cc wave
	drop if ex20100 == 0 //drop rows which are not recommended for merging
	duplicates report ID_e wave //no duplicates
	save Data\Educator_merge, replace //save new educator dataset
	
clear * 
use Raw\SC2_pCourseClass_D_6-0-0 
	drop if ex20100 == 0
	duplicates r ID_e ID_cc wave //ID_e, ID_cc and wave uniquely identify data
	
	mer 1:1 ID_cc ID_e wave using Data\Educator_merge
	duplicates r ID_e ID_cc wave
	save Data\Educator_merge, replace 

clear *
use Data\foundation  
	mer m:m ID_cc wave using Data\Educator_merge, nogen
	duplicates r ID_t wave
	sort ID_t ID_e wave
	*br ID_t ID_e ID_cc ID_i ID_group wave tx80525 tx80106 
	
	*Availability of teachers throughout the waves
	forv i = 1/6 {
		qui cou if ID_e != . & wave == `i'
		di "Available in `i'.wave: " r(N) 
		qui cou if ID_e == . & wave == `i'
		di "Unavailable in `i'.wave: " r(N) _newline
	}

sort ID_t ID_cc ID_e wave 
save Data\foundation, replace

b






******************************* PREPARATION/EXPLORATION *******************************
**** Panel Information ****
g parents_avail = tx80523



**** Gender ****
g male = 1 if tx80501 == 1
	replace male = 0 if tx80501 == 2
	

*Teacher's recommendation for tracking
	*Für welche Schulart würden Sie dieses Kind, vom jetzigen Zeitpunkt aus gesehen, empfehlen?
ta e66600a wave
g expected_school = 1 if e66600a == 1 //HS 
	replace expected_school = -1 if e66600a == 5 //Special needs school
	replace expected_school = 2 if e66600a == 2 //RS
	replace expected_school = 3 if e66600a == 4 //GS
	replace expected_school = 4 if e66600a == 3 //GY
	
	g gym_teacher_expect = 1 if expected_school == 4 
		replace gym_teacher_expect = 0 if expected_school != 4 & expected_school != .
		
ttest gym_teacher_expect if wave == 6, by(male) 
//males are 4pp less likely to get GY recommendation!


**** Aspiration ****
g ideal_aspiration = t31035d if t31035d > -54
	replace ideal_aspiration = 0 if t31035d == 4


**** Skills ****
*WLE corrected
g cskills_math_g4 = mag4_sc1 if mag4_sc1 > -55
g cskills_read_g4 = reg4_sc1 if reg4_sc1 > -55
g cskills_orto1_g4 = org4_sc1a if org4_sc1a > -55
g cskills_orto2_g4 = org4_sc1b if org4_sc1b > -55


**** NC skills ****
*Delay of gratification in 4th grade 
g delay_gratification = 1 if deg40001_c == 2
	replace delay_gratification = 0 if deg40001_c == 1



***************************** Parents *****************************
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
	
	
g male_teacher = 1 if e762110 == 1
	replace male_teacher = 0 if e762110 == 2
	
	
******************************* ANALYSIS *******************************
*------ e-Sample
reg gym_teacher_expect male cskills* ideal_aspiration delay_gratification male_teacher if wave == 6
	qui g e_gymrec = e(sample)
	
*------ Regression
eststo clear
	eststo nocontrols: qui reg gym_teacher_expect male if wave == 6 & e_gymrec, vce(cl ID_i)
	eststo math: qui reg gym_teacher_expect male cskills_math_g4 if wave == 6 & e_gymrec, vce(cl ID_i)
	eststo read: qui reg gym_teacher_expect male cskills_read_g4 if wave == 6 & e_gymrec, vce(cl ID_i)
	eststo orto: qui reg gym_teacher_expect male cskills_orto* if wave == 6 & e_gymrec, vce(cl ID_i)
	eststo aspirations: qui reg gym_teacher_expect male ideal_aspiration if wave == 6 & e_gymrec, vce(cl ID_i)
	eststo delay_gratification: qui reg gym_teacher_expect male delay_gratification if wave == 6 & e_gymrec, vce(cl ID_i)
	eststo male_teacher: qui reg gym_teacher_expect male male_teacher if wave == 6 & e_gymrec, vce(cl ID_i)
	eststo all: qui reg gym_teacher_expect male cskills* edu_mother edu_father delay_gratification if wave == 6 & e_gymrec, vce(cl ID_i)

	global estkeys nocontrols math aspirations read orto male_teacher all  
	coefplot $estkeys, sort(, by(b)) keep(male) xline(0) title(Recommendation for GY)

drop e_gymrec

*NEXT: Formulate ideas about school transition, teachers recommendation, gender
*ratios, cskills and how much they can account for the male disadvantage
*Question: How much higher test-scores/skills does a boy need to get
*the GY recommendation. Is it discrimination?









