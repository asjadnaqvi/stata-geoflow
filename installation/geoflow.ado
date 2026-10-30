*! geoflow v1.1 (30 Oct 2026)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.1 (30 Oct 2026): Automatic radius, optional arrow coordinates, and syntax and dependency fixes
* v1.0 (12 Jan 2025): First release

cap prog drop geoflow

program define geoflow, rclass
version 11
	
syntax varlist(min=1 max=1) [if] [in] using/, From(varname) To(varname) key(name) save(string) [ replace GROUPs(numlist integer max=1 >1) top(numlist integer max=1 >0) points(integer 40) geoframe radius(numlist max=1 >0) arrow mark ]
	
	
	if "`groups'" != "" {
		if `groups' <= 1 {
			display as error "Option {bf:groups()} must be greater than 1."
			exit 198
		}
	}
	if "`top'" != "" {
		if `top' <= 0 {
			display as error "Option {bf:top()} must be greater than 0."
			exit 198
		}
	}
	if `points' < 5 {
		display as error "Option {bf:points()} must be an integer greater than or equal to 5."
		exit 198
	}
	
	capture findfile arc.ado
	if _rc != 0 {
		display as error "The {bf:graphfunctions} package (including {bf:arc}) is missing. Click here to install: {stata ssc install graphfunctions, replace:graphfunctions}."
		exit 499
	}		
	
	
	if lower(substr("`using'", -4, 4)) != ".dta" local using "`using'.dta"
	capture confirm file "`using'"
	if _rc {
	   display as error "File {bf:`using'} not found."
	   exit 601
	}
	
	
	preserve
		quietly use "`using'", clear
		confirm variable `key'
		foreach v in _ID _CX _CY {
			capture confirm numeric variable `v'
			if _rc {
				display as error "File {bf:`using'} does not contain numeric variable {it:`v'}."
				exit 198
			}
		}
	restore	
	
	
	preserve 
	quietly {
	
		marksample touse, strok

		keep if `touse'
		keep `varlist' `from' `to'
		
		if "`top'"!="" {
			egen _top = rank(`varlist'), f
			keep if _top <= `top'
			drop _top	
		}


		**** exports iso3
		ren `from' `key'
		merge m:1 `key' using "`using'", keepusing(_CX _CY _ID)
		capture drop if _merge==2
		capture drop _merge
		ren `key' `from'
		ren _CX  _X1
		ren _CY  _Y1
		ren _ID fid

		levelsof `from', loca(key1)

		**** imports iso3
		ren `to' `key'
		merge m:1 `key' using "`using'", keepusing(_CX _CY _ID)
		capture drop if _merge==2
		capture drop _merge
		ren `key' `to'
		ren _CX  _X2
		ren _CY  _Y2
		ren _ID tid
		
		levelsof `to', loca(key2)

		
		drop if fid==.
		drop if tid==.
		
		count
		if r(N)==0 {
			noisily display as error "No selected flows have matching source and destination IDs."
			exit 2000
		}

		tempvar chord
		gen double `chord' = sqrt((_X2 - _X1)^2 + (_Y2 - _Y1)^2)
		count if missing(`chord') | `chord'==0
		if r(N)>0 {
			noisily display as error "Selected flows have missing coordinates, nonfinite distances, or coincident endpoints; exclude these flows before generating arcs."
			exit 459
		}
		summarize `chord', meanonly
		local minradius : display %21.17g r(max) / 2
		if "`radius'" == "" {
			// A shared radius equal to the longest chord scales with the data.
			local radius : display %21.17g r(max)
			noisily display as text "Automatic arc radius: " as result `radius'
		}
		else if `radius' < `minradius' - max(1e-12, abs(`minradius') * 1e-10) {
			noisily display as error "Option {bf:radius()} must be at least half the longest selected chord: " `minradius'
			exit 198
		}
		drop `chord'

		if "`groups'" != "" {
			xtile _group = `varlist', n(`groups')
			local myrank _group
		}

		gen _sort = _n

		// preserve the raw data
		tempfile _attributes
		save `_attributes'
		
		// arcs below
		cap drop _Y _X

		gen double _X = .
		gen double _Y = .
			
		
		levelsof _sort, local(lvls)

		foreach x of local lvls {

		summ _X1 if _sort==`x', meanonly
		local x1 = `r(mean)'

		summ _X2 if _sort==`x', meanonly
		local x2 = `r(mean)'

		summ _Y1 if _sort==`x', meanonly
		local y1 = `r(mean)'

		summ _Y2 if _sort==`x', meanonly
		local y2 = `r(mean)'


		arc, y1(`y1') x1(`x1') y2(`y2') x2(`x2') radius(`radius') genx(_X) geny(_Y) genid(_ID) genorder(_ORDER) n(`points') append

		}

	
		keep _X _Y _ID _ORDER

		if "`arrow'" != "" {
			sort _ID _ORDER
			// arc appends a missing-coordinate separator after the final point.
			tempvar pointrow lastpoint
			by _ID: gen long `pointrow' = _n if !missing(_X, _Y)
			by _ID: egen long `lastpoint' = max(`pointrow')
			by _ID: gen double _arrow_y1 = _Y[_n-1] if _n==`lastpoint'
			by _ID: gen double _arrow_x1 = _X[_n-1] if _n==`lastpoint'
			by _ID: gen double _arrow_y2 = _Y if _n==`lastpoint'
			by _ID: gen double _arrow_x2 = _X if _n==`lastpoint'
			drop `pointrow' `lastpoint'
		}

		ren _ID _sort
		
		local arrowvars
		if "`arrow'" != "" local arrowvars _arrow_y1 _arrow_x1 _arrow_y2 _arrow_x2
		merge m:1 _sort using `_attributes', keepusing(`from' `to' `varlist' `myrank')
		rename _sort _ID
		capture drop _merge
			
		order `from' `to' `varlist' _ID _Y _X _ORDER `myrank' `arrowvars'

		compress
		
		if "`replace'" != "" {
			save "`save'", replace
		}
		else {
			save "`save'"
		}
				
		noisily display in yellow "File {it:`save'.dta} saved."
		
		
		if "`geoframe'" != "" {
			noisily geoframe create `save', replace 
		}
	
	}
	restore
	
	if "`mark'"!="" {
		quietly {
		preserve
			use "`using'", clear
			capture drop _mark
			gen _mark = .
			
			capture confirm string variable `key'
			if _rc {
				foreach x of local key1 {
					replace _mark = 1 if `key'==`x'
				}
				foreach x of local key2 {
					replace _mark = 1 if `key'==`x'
				}
			}
			else {
				foreach x of local key1 {
					replace _mark = 1 if `key'==`"`x'"'
				}
				foreach x of local key2 {
					replace _mark = 1 if `key'==`"`x'"'
				}
			}
			
			save, replace
			
		restore
		}
	}
	
	return scalar arcradius = `radius'
	
end


************************
***** END OF FILE ******
************************
