*! geoflow v1.0 (12 Jan 2025)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.0 (12 Jan 2025): First release

cap prog drop geoflow

program define geoflow, rclass 
version 11
	
syntax varlist(min=1 max=1) [if] [in] using/, From(varname) To(varname) key(string) save(string) [ replace GROUPs(numlist max=1 >1) top(numlist max=1 >0) points(real 40) geoframe radius(real 350) mark  ]
	
	
	return local arcradius = `radius'
	
	capture findfile shapes.ado
	if _rc != 0 {
		display as error "The {bf:graphfunctions} package is missing. Click here to install: {stata ssc install graphfunctions, replace:graphfunctions}."
		exit
	}		
	
	
	if (substr(reverse("`using'"),1,4) != "atd.") local using "`using'.dta"
	capture confirm file "`using'"
	if _rc {
	   display as error "File {bf:`using'} not found."
	   exit 601
	}
	
	
	preserve
		quietly use "`using'", clear
		capture confirm numeric variable _ID _CX _CY
		if _rc {
		   display as error "File {bf:`using'} does not contain variables {it:_ID}, {it:_CX}, {it:_CY}."
		   exit 198
		}
	restore	
	
	
	preserve 
	quietly {
	
		marksample touse, strok

		keep if `touse'

		keep `varlist' `by' `exp' `from' `to'
		
		if "`top'"!="" {
			egen _top = rank(`varlist'), f
			keep if _top <= `top'
			drop _top	
		}


		**** exports iso3
		ren `from' `key'
		merge m:1 `key' using `using', keepusing(_CX _CY _ID)
		drop if _m==2
		drop _m
		ren `key' `from'
		ren _CX  _X1
		ren _CY  _Y1
		ren _ID fid

		levelsof `from', loca(key1)

		**** imports iso3
		ren `to' `key'
		merge m:1 `key' using `using', keepusing(_CX _CY _ID)
		drop if _m==2
		drop _m
		ren `key' `to'
		ren _CX  _X2
		ren _CY  _Y2
		ren _ID tid
		
		levelsof `to', loca(key2)

		
		drop if fid==.
		drop if tid==.
		

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
		ren _ID _sort
		
		merge m:1 _sort using `_attributes', keepusing(`from' `to' `varlist' `myrank')
		ren _sort _ID
		drop _m
			
		order `from' `to' `varlist' _ID  _Y _X  _ORDER  `myrank'

		compress
		
		if "`replace'" != "" {
			save `save', replace
		}
		else {
			save `save'
		}
				
		noisily display in yellow "File {it:`save'.dta} saved."
		
		
		if "`geoframe'" != "" {
			noisily geoframe create `save', replace 
		}
	
	*/
	
	}
	restore
	
	if "`mark'"!="" {
		quietly {
		preserve
			use `using', clear
			capture drop _mark
			gen _mark = .
			
			foreach x of local key1 {
				replace _mark = 1 if `key'=="`x'"
			}
			
			foreach x of local key2 {
				replace _mark = 1 if `key'=="`x'"
			}
			
			save, replace
			
		restore
		}
	}
	
	
end


************************
***** END OF FILE ******
************************
