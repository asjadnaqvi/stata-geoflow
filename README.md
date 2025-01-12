
![StataMin](https://img.shields.io/badge/stata-2015-blue) ![issues](https://img.shields.io/github/issues/asjadnaqvi/stata-geoflow) ![license](https://img.shields.io/github/license/asjadnaqvi/stata-geoflow) ![Stars](https://img.shields.io/github/stars/asjadnaqvi/stata-geoflow) ![version](https://img.shields.io/github/v/release/asjadnaqvi/stata-geoflow) ![release](https://img.shields.io/github/release-date/asjadnaqvi/stata-geoflow)

[Installation](#Installation) | [Syntax](#Syntax) | [Examples](#Examples) | [Feedback](#Feedback) | [Disclaimer](#Disclaimer)  | [Change log](#Change-log)

---


![geoflow_banner](https://github.com/user-attachments/assets/7c112955-dac5-446c-9e2e-a2230cee893a)



# geoflow v1.0
(12 Jan 2025)

A package for generating flow arcs using GIS data.

**Note 1**: GIS files are large and quickly accumulate. Please try and download exacly what you need. Please also avoid repeated downloading of the same datasets.

**Note 2**: If you are bulk downloading multiple datasets in directories where disk writing is slower than the download speed, then you might get return or I/O errors even if the file is valid. This could potentially occur if downloading directly on to cloud storage (e.g. Dropbox, OneDrive, etc.), or using slower hard drives (e.g. 5400 rpm, non SATA etc.). In this case, either download the files somewhere else, or wait for the files to synchronize and try again.


## Installation

The package can be installed via SSC or GitHub. The GitHub version, *might* be more recent due to bug fixes, feature updates etc, and *may* contain syntax improvements and changes in *default* values. See version numbers below. Eventually the GitHub version is published on SSC.

The SSC version (**v1.0**):

```stata
COMING SOON
```

Or it can be installed from GitHub (**v1.0**):

```stata
net install geoflow, from("https://raw.githubusercontent.com/asjadnaqvi/stata-geoflow/main/installation/") replace
```

Install the following dependencies:

```stata
ssc install graphfunctions, replace
```

Additional code for the maps shown below:


```stata
ssc install schemepack, replace
set scheme white_tableau  

graph set window fontface "Arial Narrow"
```


## Citation guidelines
Software packages take countless hours of programming, testing, and bug fixing. If you use this package, then a citation would be highly appreciated:


Click here for the latest [SSC citation](XXXX).


otherwise the following BibTeX citation can be used:

```BibTeX
@software{geoflow,
   author = {Naqvi, Asjad},
   title = {Stata package ``geoflow''},
   url = {https://github.com/asjadnaqvi/stata-geoflow},
   version = {1.0},
   date = {2025-01-12}
}
```



## Syntax



```stata
geoflow numvar [if] [in] {using}, from(varname) to(varname) key(var) saving(filename) [ replace cuts(num) top(num) points(num) ] 

```



See `help geoflow` for details.


## Examples

Get the global boundary data using the latest version of the [geoboundary](https://github.com/asjadnaqvi/stata-geoboundary) package:

```stata
geoboundary WLD, replace convert remove source(worldbank) 
```

Clean it up a up since ISO3 values have duplicates due to territories:

```
use WB_ADM0, clear
	duplicates list ISO_A3
	drop if ISO_A3=="-99"
	drop if TYPE=="Dependency"
	drop if inlist(WB_A3, "BES", "TKL")

compress
save iso_meta, replace 
```

This create our master nodes file that also contains the locations.


Load the sample trade data file derived from COMTRADE [BACI](https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=37) for 2022:

```
use "https://github.com/asjadnaqvi/stata-geoflow/blob/main/GIS/baci_2022.dta?raw=true", clear
```

Create flow arcs for the top 20 values:

```stata
geoflow value using iso_meta, from(ex_iso3) to(im_iso3) key(ISO_A3) top(20) save(links) geoframe replace mark
```

Also see `return list` that stores the radius value in local `r(georadius)`. Since we specified the `geoframe` option, we can view the data by switching to this frame: `frame change links`.

Now create another frame that contains the boundaries and the node attributes:

```stata
geoframe create metadata iso_meta, replace shp(WB_ADM0_shp)
```

Note here that we are using the our cleaned up file for the attributes. You can view the data by switching to this frame `frame change metadata`.

Plot the information:

```stata
geoplot ///
	 (area metadata i.REGION_WB, color(%40) lw(0.1) lc(white))	///
	 (line links i._ID, lwidth(0.4) color(black) )	///
	 (point metadata [w=GDP_MD_EST] if _mark==1, color(white%95) msize(1.6) mlcolor(black) )	///
	 (label metadata ISO_A3 		if _mark==1, color(black)   size(1.5)  			 )	///
	 , tight legend(pos(7)) ///
	 title("Top 20 trade flows in 2022") note("Source: COMTRADE BACI")
```

<img src="/GIS/geoflow1.png" width="100%">



## Feedback

Please open an [issue](https://github.com/asjadnaqvi/stata-geoflow/issues) to report errors, feature enhancements, and/or other requests. 


## Change log

**v1.0 (12 Jan 2025)**
- First release





