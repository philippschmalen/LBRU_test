clear *
cap log close
set more off, permanently

/* FILE STRUCTURE IN DIRECTORY

		1	Dofiles
		2	Logfiles
		3	Raw		-- Do not touch!
		4	Tables
		5	Graphs
		6	Data
*/

*Define Path
global path_phil = "C:\Users\Philipp\GDrive\VWL\NEPS Dropout\Data_SC3"
global path_alexander = "C:\Users\Alexander\GDrive\VWL\NEPS Dropout\Data_SC3"

cd $path_phil //path_alexander
cap log using Logfiles\analysis_sc3_7-0-0.txt, text replace
use Data\analysis //analysis.do is main file



******************************* Test Box for me *******************************

*--------------------------------------- EDU RISE
quietly reg edu_rise $ses $nc $c $basic 
	g e_rise = e(sample)
	

******************************* DATA ANALYSIS *******************************
*------------------------------------------------------------------------------------------------------------
* Control Variables
*------------------------------------------------------------------------------------------------------------
global basic age_std age_squared_std migrant health_eval_std east_west  
global ses low_ses malexlow_ses //single_parent edu_*_years_std hh_siblingspresent hh_size
	//grad_mother_std grad_father_std single_mother single_father hh_unknown
	//low_income_male gradm_male_std gradf_male_std child_parents_attitude_std family_sa_std
global c cskills_*_g5_std 
	//reasoning_std percept_speed_std reading_speed_std math_score_std 
	//vocabulary_score_std ict_score_std scientific_literacy_std reading_score_std  declarative_std (META)
global nc self_esteem_std malexselfesteem_std  // homework_time german_selfconcept_std ///
		//math_selfconcept_std school_selfconcept_std missing_schooldays edu_attitude_std 
	// sdq_* bf_* sensitivity_std illusion_std  sport_std 
global outcome grade_repeated grades_skipped grade_*_std aspiration_ideal_std malexaspiration_std //attitude_school_indifferent 
	//uncertain attrition_college_track
global gym_dropout ctrack_dropout_nomiss ctrack_dropout_allmiss ctrack_dropout_diff dropout edu_rise 
global weights //ID_i ID_t w_i stratum_exp w_t w_t1 w_t2 w_t12 w_t3 w_t123 w_t4 w_t1234 ///
	//w_t5 w_t1235 w_t6 w_t12356 w_t7 w_t12357 w_t8 w_t123578 w_t9 w_t1235789 w_t1_ca

* Remove time dimension
drop if wave > 1
drop wave

*------------------------------------------------------------------------------------------------------------
* Create Subsamples with e(sample)
*------------------------------------------------------------------------------------------------------------
*--------------------------------------- IDEAL ASPIRATION
quietly reg aspiration_ideal_std $ses $nc $c $basic 
	g e_aspiration = e(sample)	
*--------------------------------------- GYM DROPOUT
quietly reg gym_dropout $ses $nc $c $basic 
	g e_gymdropout = e(sample)
*--------------------------------------- CTRACK DROPOUT NOMISS
quietly reg ctrack_dropout_nomiss $ses $nc $c $basic 
	g e_cdropout_nomiss = e(sample)
*--------------------------------------- CTRACK DROPOUT ALLMISS
quietly reg ctrack_dropout_allmiss $ses $nc $c $basic 
	g e_cdropout_allmiss = e(sample)
*--------------------------------------- GRADE REPEATED
quietly reg grade_repeated $ses $nc $c $basic 
	g e_graderepeat = e(sample)
*--------------------------------------- EDU RISE
quietly reg edu_rise $ses $nc $c $basic 
	g e_rise = e(sample)

	
*ident bottlenecks
foreach x of varlist e_* { 
	su $basic $ses $c $nc $outcome if `x' == 1
}

	
*Standardize within samples
*Make sure that standardization was done for the samples
local i = 1
foreach e of varlist e_*{
	foreach x of varlist *std {
		quietly egen `x'`i' = std(`x') if `e' == 1
	}
	local i = `i' + 1
}


b
******************************* Descriptives *******************************
*------------------------------------------------------------------------------------------------------------
* Characteristics by School type 
*------------------------------------------------------------------------------------------------------------
global schools male $ses $nc $c $outcome migrant

eststo clear
	foreach i of numlist -1 1 2 3 4{
		eststo: quietly estpost su $schools if edutype == `i'
	}
esttab, main(mean) aux(sd) wrap wide compress nonum star(* 0.10 ** 0.05 *** 0.01) /// //using Tables/tables, append booktabs label
	title("School Summary Statistics w/o Sample Restrictions") mtitle("OR" "HS" "RS" "GS" "GY")


*------------------------------------------------------------------------------------------------------------
* Gender Differences: HS
*------------------------------------------------------------------------------------------------------------
global gender $ses $nc $c $outcome migrant
eststo clear
	eststo: quietly estpost su $gender if male == 1 & edutype == 1
	eststo: quietly estpost su $gender if male == 0 & edutype == 1
	eststo: quietly estpost ttest $gender if edutype == 1, by(male)
esttab, main(mean) aux(sd) wrap wide compress nonum star(* 0.10 ** 0.05 *** 0.01) /// //  using Tables\tables, booktabs append label 
	title("Means by Gender") mtitle("Male" "Female" "") ///
	addn("All coefficients are standardized. Higher values for grade indicate better.")


*------------------------------------------------------------------------------------------------------------
* Gender Differences: RS
*------------------------------------------------------------------------------------------------------------
global gender $ses $nc $c $outcome migrant
eststo clear
	eststo: quietly estpost su $gender if male == 1 & edutype == 2
	eststo: quietly estpost su $gender if male == 0 & edutype == 2
	eststo: quietly estpost ttest $gender if edutype == 2, by(male)
esttab , main(mean) aux(sd) wrap wide compress nonum star(* 0.10 ** 0.05 *** 0.01) /// // using Tables\tables, booktabs append label 
	title("Means by Gender: RS") mtitle("Male" "Female" "") ///
	addn("All coefficients are standardized. Higher values for grade indicate better.")
	

*------------------------------------------------------------------------------------------------------------
* Gender Differences: GS
*------------------------------------------------------------------------------------------------------------
global gender $ses $nc $c $outcome migrant
eststo clear
	eststo: quietly estpost su $gender if male == 1 & edutype == 3
	eststo: quietly estpost su $gender if male == 0 & edutype == 3
	eststo: quietly estpost ttest $gender if edutype == 3, by(male)
esttab, main(mean) aux(sd) wrap wide compress nonum star(* 0.10 ** 0.05 *** 0.01) /// //using Tables\tables, booktabs append label 
	title("Means by Gender: GS/OTHER") mtitle("Male" "Female" "") ///
	addn("All coefficients are standardized. Higher values for grade indicate better.")


*------------------------------------------------------------------------------------------------------------
* Gender Differences: GY
*------------------------------------------------------------------------------------------------------------
global gender $ses $nc $c $outcome migrant
eststo clear
	eststo: quietly estpost su $gender if male == 1 & edutype == 4
	eststo: quietly estpost su $gender if male == 0 & edutype == 4
	eststo: quietly estpost ttest $gender if edutype == 4, by(male)
esttab, main(mean) aux(sd) wrap wide compress nonum star(* 0.10 ** 0.05 *** 0.01) /// //using Tables\tables, booktabs append label 
	title("Means by Gender: GY") mtitle("Male" "Female" "") ///
	addn("All coefficients are standardized. Higher values for grade indicate better.")
	

*------------------------------------------------------------------------------------------------------------
* Dropout Variable Differences: ctrack_dropout_diff
*------------------------------------------------------------------------------------------------------------
global gender $basic $ses $nc $c $outcome
eststo clear
	eststo: quietly estpost su $gender if ctrack_dropout_diff == 1 
	eststo: quietly estpost su $gender if ctrack_dropout_diff == 0 
	eststo: quietly estpost ttest $gender, by(ctrack_dropout_diff)
esttab, main(mean) aux(sd) wrap wide compress nonum star(* 0.10 ** 0.05 *** 0.01)  /// //using Tables\tables, booktabs append label 
	title("Means by Missing and Non-Missing CTrack Dropout variable codings") mtitle("Only Missings" "No Missings" "") ///
	addn("All coefficients are standardized.")
	



	
******************************* Regression Analysis *******************************
*------------------------------------------------------------------------------------------------------------
* GY Dropout
*------------------------------------------------------------------------------------------------------------
eststo clear 
	eststo: quietly reg gym_dropout male $basic 				if e_gymdropout //
	eststo: quietly reg gym_dropout male $basic $ses 			if e_gymdropout //
	eststo: quietly reg gym_dropout male $basic $nc 			if e_gymdropout //
	eststo: quietly reg gym_dropout male $basic $c				if e_gymdropout //	
	eststo: quietly reg gym_dropout male $basic $ses $nc $c 	if e_gymdropout //  
	eststo: quietly reg gym_dropout male $basic $ses $nc $c 	if male == 1 			//
	eststo: quietly reg gym_dropout male $basic $ses $nc $c 	if male == 0 			//	
esttab ,  r2 se noomit wrap compress star(* 0.10 ** 0.05 *** 0.01) /// // using Tables/tables.tex, booktabs append label
	title("GY Dropout if not at GY in Wave 7" ) ///
	mtitles("All" "All" "All" "All" "All" "Male" "Female") ///
	indicate("Basic Controls = $basic") /// //"Ability = $c" 
	addn("Linear Probability Model; clustered standard errors (school level)" ///
		"Basic Controls: $basic" "Ability: $c")

*------------------------------------------------------------------------------------------------------------
* College Track Dropout
*------------------------------------------------------------------------------------------------------------
eststo clear 
	eststo: quietly reg ctrack_dropout_nomiss male $basic 				if e_cdropout_nomiss //
	eststo: quietly reg ctrack_dropout_nomiss male $basic $ses 			if e_cdropout_nomiss //
	eststo: quietly reg ctrack_dropout_nomiss male $basic $nc 			if e_cdropout_nomiss //
	eststo: quietly reg ctrack_dropout_nomiss male $basic $c			if e_cdropout_nomiss //	
	eststo: quietly reg ctrack_dropout_nomiss male $basic $ses $nc $c 	if e_cdropout_nomiss //  
	eststo: quietly reg ctrack_dropout_nomiss male $basic $ses $nc $c 	if male == 1 			//
	eststo: quietly reg ctrack_dropout_nomiss male $basic $ses $nc $c 	if male == 0 			//
esttab ,  r2 se noomit wrap compress star(* 0.10 ** 0.05 *** 0.01) /// // using Tables/tables.tex, booktabs append label
	title("College Track Dropout (no missings)" ) ///
	mtitles("All" "All" "All" "All" "All" "Male" "Female") /// 
	indicate("Basic Controls = $basic") /// //"Ability = $c" 
	addn("Linear Probability Model; clustered standard errors (school level)" ///
		"Basic Controls: $basic" "Ability: $c")
		
eststo clear 
	eststo: quietly reg ctrack_dropout_allmiss male 					if e_cdropout_allmiss //
	eststo: quietly reg ctrack_dropout_allmiss male $basic $ses 		if e_cdropout_allmiss //
	eststo: quietly reg ctrack_dropout_allmiss male $basic $nc 			if e_cdropout_allmiss //
	eststo: quietly reg ctrack_dropout_allmiss male $basic $c			if e_cdropout_allmiss //	
	eststo: quietly reg ctrack_dropout_allmiss male $basic $ses $nc $c 	if e_cdropout_allmiss //  
	eststo: quietly reg ctrack_dropout_allmiss male $basic $ses $nc $c 	if male == 1 			//
	eststo: quietly reg ctrack_dropout_allmiss male $basic $ses $nc $c 	if male == 0 			//
esttab ,  r2 se noomit wrap compress star(* 0.10 ** 0.05 *** 0.01) /// // using Tables/tables.tex, booktabs append label
	title("College Track Dropout (all, incl. missings)" ) ///
	mtitles("All" "All" "All" "All" "All" "Male" "Female") /// 
	indicate("Basic Controls = $basic") /// //"Ability = $c" 
	addn("Linear Probability Model; clustered standard errors (school level)" ///
		"Basic Controls: $basic" "Ability: $c")
		
*------------------------------------------------------------------------------------------------------------
* Regressions conditional on quantiles
*------------------------------------------------------------------------------------------------------------
	g quartile = .
	qui su grade_mat_std, d
	forv i = 25(25)75 {
		qui replace quartile = `i' if r(p`i')
	}
	
eststo clear
eststo: quietly reg ctrack_dropout_allmiss male if grade_mat_std < q25
eststo: quietly reg ctrack_dropout_allmiss male if grade_mat_std >= q25 & grade_mat_std <= q50
eststo: quietly reg ctrack_dropout_allmiss male if grade_mat_std >= q50 
coefplot (est1, label(<25)) (est2, label(25-50)) (est3, label(>50)), ///
	drop(_cons) vertical recast(bar) ciopts(recast(rcap)) citop barwidt(0.1) ///
	ylabel(0(5)20) rescale(100) title()
	
	
	drop quartile
b	
	
statsby _b _se e(r2_a), clear: reg ctrack_dropout_allmiss male
foreach var in male {
    gen t_`var' = _b_`var'/_se_`var'
}

	
	

	su grade_ger_std, d
	forv i = 25(25)75 {
		g q`i' = r(p`i')
	}
eststo clear
eststo: quietly reg  ctrack_dropout_allmiss male if grade_ger_std < q25
eststo: quietly reg  ctrack_dropout_allmiss male if grade_ger_std >= q25 & grade_ger_std <= q50
eststo: quietly reg  ctrack_dropout_allmiss male if grade_ger_std >= q50 & grade_ger_std <= q75
eststo: quietly reg  ctrack_dropout_allmiss male if grade_ger_std > q75
	drop q25-q75


b
*------------------------------------------------------------------------------------------------------------
* Aspirations across Edutype
*------------------------------------------------------------------------------------------------------------
eststo clear 
	eststo: quietly reg aspiration_ideal_std  male $basic $ses $nc $c 	if e_aspiration & edutype == 1 //  
	eststo: quietly reg aspiration_ideal_std  male $basic $ses $nc $c 	if e_aspiration & edutype == 2  //  
	eststo: quietly reg aspiration_ideal_std  male $basic $ses $nc $c 	if e_aspiration & edutype == 3  //  
	eststo: quietly reg aspiration_ideal_std  male $basic $ses $nc $c 	if e_aspiration & edutype == 4  //  
	eststo: quietly reg aspiration_ideal_std  male $basic $ses $nc $c 	if e_aspiration  //  
	eststo: quietly reg aspiration_ideal_std  male $basic $ses $nc $c 	if male == 1 			//
	eststo: quietly reg aspiration_ideal_std  male $basic $ses $nc $c 	if male == 0 			//
esttab ,  r2 se noomit wrap compress star(* 0.10 ** 0.05 *** 0.01) /// // using Tables/tables.tex, booktabs append label
	title("Aspiration_ideal_std" ) ///
	mtitles("HS" "RS" "GS" "GY" "All" "Male" "Female") /// //	 /// 
	indicate("Basic Controls = $basic") /// //"Ability = $c" 
	addn("clustered standard errors (school level)" ///
		"Basic Controls: $basic" "Ability: $c")


*------------------------------------------------------------------------------------------------------------
* Grade repeated
*------------------------------------------------------------------------------------------------------------
eststo clear 
	eststo: quietly reg grade_repeated  male $basic 			 	if e_graderepeat //  
	eststo: quietly reg grade_repeated  male $basic $ses 			if e_graderepeat //  
	eststo: quietly reg grade_repeated  male $basic $nc 			if e_graderepeat //  
	eststo: quietly reg grade_repeated  male $basic $c 				if e_graderepeat // 
	eststo: quietly reg grade_repeated  male $basic $ses $nc $c		if e_graderepeat //  	
	eststo: quietly reg grade_repeated  male $basic $ses $nc $c 	if male == 1 			//
	eststo: quietly reg grade_repeated  male $basic $ses $nc $c 	if male == 0 			//
esttab ,  r2 se noomit wrap compress star(* 0.10 ** 0.05 *** 0.01) /// // using Tables/tables.tex, booktabs append label
	title("grade_repeated" ) ///
	mtitles("All" "All" "All" "All" "All" "Male" "Female") /// //	 /// 
	indicate("Basic Controls = $basic") /// //"Ability = $c" 
	addn("clustered standard errors (school level)" ///
		"Basic Controls: $basic" "Ability: $c")


*------------------------------------------------------------------------------------------------------------
* Educational Upward Mobility
*------------------------------------------------------------------------------------------------------------
eststo clear 
	eststo: quietly reg edu_rise male $basic 			 	if e_rise //  
	eststo: quietly reg edu_rise male $basic $ses 			if e_rise //  
	eststo: quietly reg edu_rise male $basic $nc 			if e_rise //  
	eststo: quietly reg edu_rise male $basic $c 			if e_rise //  
	eststo: quietly reg edu_rise male $basic $ses $c $nc	if e_rise //  
	eststo: quietly reg edu_rise male $basic $ses $nc $c 	if male == 1 			//
	eststo: quietly reg edu_rise male $basic $ses $nc $c 	if male == 0 			//
esttab ,  r2 se noomit wrap compress star(* 0.10 ** 0.05 *** 0.01) /// // using Tables/tables.tex, booktabs append label
	title("edu_rise" ) ///
	mtitles("All" "All" "All" "All" "All" "Male" "Female") /// //	 /// 
	indicate("Basic Controls = $basic") /// //"Ability = $c" 
	addn("clustered standard errors (school level)" ///
		"Basic Controls: $basic" "Ability: $c")
		

