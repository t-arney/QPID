# QPID

The Quaternary Palaeoclimate Isotope Database

> Creator and maintainer: Thomas Arney [![ORCID iD icon](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0003-4380-4079)\
> Current version: 1.0 (Sept. 2020)\
> Size: 141236 data points from 396 locations\
> Measurements: benthic and planktic foraminiferal calcite &delta;<sup>18</sup>O and &delta;<sup>13</sup>C

This is a compilation of published worldwide Quaternary marine stable isotope data from foraminifera, using compilations by [Oliver *et al.* (2009)](https://doi.org/10.5194/cp-6-645-2010) and [Jonkers *et al.* (2020)](https://doi.org/10.5194/essd-12-1053-2020) as starting points (though this is not a complete superset of those studies).

This compilation is structured like a simple relational database, with five tables in the `/data` directory. For the full dataset as a flat CSV file, check the [`/data/compiled`](./data/compiled/full_dataset.csv) directory (but see [note](#fallback)).

The [docs readme](/docs/README.md) has more details about the database-style source tables and the data and metadata attributes. The docs directory also includes a list of references cited in the data tables.

The [src](/src) directory includes the code used to compile the database.

## Using the data

The data included in this database revolves around the idea of one physical sample, with its primary data stored in one table (`samples`) and the metadata (which it shares with many other samples) stored in other tables (`sites` for the positional data it was collected at; `taxa` for the species (taxon) of foraminifera which was analysed; and `studies` for the paper or report in which the data was published).

This kind of architecture is called “relational,” since the tables are related to each other via one or more attributes. in this case, the `samples` table has links to the other tables in the attributes `site_name`, `taxon_id`, and `citekey`, which match to the same attribute in the `sites`, `taxa`, and `studies` tables respectively.

Although it may be easier to work with a huge table which has all data and metadata together, this can get very large very quickly. Such a table for this database is around 30 MB, but by splitting into relational tables (and therefore avoiding a lot of repetition), the sum of the parts is only 8 MB between five files. Given that for most purposes only one or two of the metadata tables will be relevant to an analysis, the advantage is clear. Merging the tables during an analysis is relatively easy (even in Excel).

The database is presented in four formats (CSV tables, an R Data Store (`.rds`) file, a MATLAB MAT-file (`.mat`), and an Excel workbook, with a fallback CSV file).

### CSV tables

The CSV format is easily shared and read by many applications and languages, and so is the main format for this database. Although these files have split the attributes into relational-style tables, analysing data is usually easiest on 'flat' files. If you need data from more than one of the database-style CSVs, you should filter one of the source tables first (preferably `samples`, the largest), then merge with any other tables you need, since filtering and then merging is a less memory-intensive operation than merging all tables and then filtering.

For example, extracting only Northeast Atlantic ([`NEAt`](/docs/README.md#ocean-basin)) &delta;<sup>18</sup>O records to plot (so we don’t need the metadata) in R:

```R
# import sites table (your file path may vary)
sites <- read.csv('../data/sites.csv')

# get only North Atlantic records (NAt):
sites_filt <- sites[sites$ocean_basin == 'NEAt', ]

# now we can remove the original sites table from memory:
rm(sites)

# import the samples CSV table. We only want data, not metadata, so we don't need 
# the other tables for this example (and save memory by not loading them)
samples <- read.csv('../data/samples.csv')

# merge the tables, keeping only the samples from sites in our filtered list
NEAt_samples <- merge(sites_filt, samples, by = "site_name", all.x = TRUE)

# now we can remove the original tables
rm(sites_filt, samples)

# do some analysis here...
# or save to a CSV for analysing elsewhere
```

Note: If you are reading the CSV files into Excel yourself, you may encounter problems if the file includes special characters (this is true especially of the [`studies`](/docs/README.md#studies) table). Use the provided [Excel workbook](#excel-workbook) where possible, or if not, see the note about Excel encoding [below](#excel-and-encoding).

### RDS file

Since the database was built with R, the data is also available in [one RDS file](/data/compiled/qpid.rds) to avoid the calls to `read.csv()`. As with the CSV tables, filtering and then merging is probably the best way to use the data:

```R
# load the database (your file path may vary)
load('../data/compiled/qpid.rds')

# get only North Atlantic records (NAt):
sites_filt <- sites[sites$ocean_basin == 'NEAt', ]

# merge the tables, keeping only the samples from sites in our filtered list
NEAt_samples <- merge(sites_filt, samples, by = "site_name", all.x = TRUE)

# do some analysis here...
```

### MATLAB MAT-file

The CSV files have been imported with the correct formats and encoding and stored in a [MAT-file](/data/compiled/qpid.mat) for use in MATLAB. To access just one table without loading everything into memory, use the [`matfile()`](https://www.mathworks.com/help/matlab/ref/matlab.io.matfile.html) command. To merge the tables (after filtering), use a [left outer join](https://www.mathworks.com/help/matlab/ref/outerjoin.html) with `samples` as the left table:

```MATLAB
% load the (full) database (your file path may vary)
load('../data/compiled/qpid.mat')

% Join sites and samples tables (on site_name key)
joinedData = outerjoin(samples,sites,'Type','left','Keys','site_name','MergeKeys',true)
```

### Excel workbook

A Microsoft Excel workbook (`.xlsx`) containing each table as a sheet is also [provided](/data/compiled/QPID.xlsx), which may be useful to gain a quick overview of the data, though analysis will probably be limited. Consider converting the tables themselves to [Excel tables](https://support.microsoft.com/en-us/office/overview-of-excel-tables-7ab0bb7d-3a9e-4b56-a3c9-6c94334e492c) for easier manipulation.

#### Merging in Excel

Excel’s [`XLOOKUP()`](https://support.microsoft.com/en-us/office/xlookup-function-b7fd680e-6d10-43e6-84f9-88eae8bf5929) formula (or the older [`VLOOKUP()`](https://support.microsoft.com/en-us/office/vlookup-function-0bbc8083-26fe-4963-8ab8-93a18ad188a1)) allows the metadata to be linked to the data. Consider these records from the `samples` table (some columns omitted):

| site_name | depth_in_core | age   | taxon_id   | ... | d18o  | d13c   |
| --------- | ------------- | ----- | ---------- | --- | ------| ------ |
| ODP1089   | 2.02          | 15.25 | Cibicidods | ... | 3.870 | -0.800 |
| ODP1089   | 2.02          | 15.25 | G_bulloids | ... | 2.890 | 0.110  |

We might want to compare planktic and benthic data, so we add a column for the habitat. In the formula, we get the `taxon_id` (column D), find it in the `taxon_id` column of the `taxa` table (column A) to look up the associated `habitat` (column F) from the `taxa` table :

| site_name | depth_in_core | age   | taxon_id   | ...  | d18o  | d13c   | habitat                                         |
| --------- | ------------- | ----- | ---------- | ---- | ----- | ------ | ----------------------------------------------- |
| ODP1089   | 2.02          | 15.25 | Cibicidods | ...  | 3.870 | -0.800 | `=XLOOKUP($D1,taxa!$A$2:$A$93,taxa!$F$2:$F$93)` |
| ODP1089   | 2.02          | 15.25 | G_bulloids | ...  | 2.890 | 0.110  | `=XLOOKUP($D2,taxa!$A$2:$A$93,taxa!$F$2:$F$93)` |

giving:

| site_name | depth_in_core | age   | taxon_id   | ... | d18o  | d13c  | habitat |
| --------- | ------------- | ----- | ---------- | --- | ----- | ----- | ------- |
| ODP1089   | 2.02          | 15.25 | Cibicidods | ... | 3.870 | -0.80 | Bn      |
| ODP1089   | 2.02          | 15.25 | G_bulloids | ... | 2.890 | 0.110 | Pl      |

#### Excel and encoding

Microsoft Excel has trouble reading a normal UTF-8 encoded file with special characters in it: for example, characters with diacritics (e.g. ä, é, ø, etc.) may be rendered as something like `Ã¼` or `�`. Excel needs a ‘byte order mark’ [(BOM)](https://en.wikipedia.org/wiki/Byte_order_mark) to correctly render these characters, which can be added by opening the file in a text editor and re-saving it with the encoding set to “unicode with BOM” or “UTF-8 (BOM)” or similar. However, other apps and languages do not like the BOM – for example, if you [try and load](https://stackoverflow.com/questions/15259139) a UTF-8 (BOM) CSV file in R, it will call the first column a name that starts with `ï..` .

Alternatively, you can add the CSV as a data source to a blank workbook via Data > Get & Transform Data > From Text/CSV, and choosing “65001: Unicode (UTF-8)” as the File Origin.

### Fallback

If for any reason filtering and merging is not possible using any of the other formats, the full dataset with all attributes is available in one large CSV [here](/data/compiled/qpid_full_dataset.csv).

Warning: this table is very large for a text file (>30 MB in v1.0). Some applications may struggle to load it, limit what you can do with it, or it may approach or exceed the memory available on your machine.

## Contributing

If you have data to contribute, if you spot an error, or if you can see something to improve, please feel free to submit an [issue](https://github.com/t-arney/QPID/issues) or a [pull request](https://github.com/t-arney/QPID/pulls).
