# CAMEO codes for `search_events.sh`

From GDELT's own lookup tables (`gdeltproject.org/data/lookups/CAMEO.country.txt`, `CAMEO.eventcodes.txt`), checked against what the corpus actually carries. Counts are from a full streamed pass over 1979-01-01 .. 2013-03-31 plus all of 2020; for countries they count actor slots (Actor1 and Actor2 each), not events.

## `-r ROOT` — the 20 event roots

`-r` is a regex anchored to the whole two-digit code: `-r 14`, `-r '18|19'`, `-r '1[5-9]|20'`.

| root | meaning | quad class | events |
|---|---|---|---:|
| `01` | Make public statement | 1 verbal cooperation | 36,904,306 |
| `02` | Appeal | 1 verbal cooperation | 18,213,929 |
| `03` | Express intent to cooperate | 1 verbal cooperation | 19,457,340 |
| `04` | Consult | 1 verbal cooperation | 66,927,353 |
| `05` | Engage in diplomatic cooperation | 1 verbal cooperation | 19,569,325 |
| `06` | Engage in material cooperation | 2 material cooperation | 5,614,943 |
| `07` | Provide aid | 2 material cooperation | 8,039,830 |
| `08` | Yield | 2 material cooperation | 9,393,677 |
| `09` | Investigate | 2 material cooperation | 4,806,569 |
| `10` | Demand | 3 verbal conflict | 3,611,018 |
| `11` | Disapprove | 3 verbal conflict | 16,005,718 |
| `12` | Reject | 3 verbal conflict | 6,905,015 |
| `13` | Threaten | 3 verbal conflict | 3,756,575 |
| `14` | Protest | 3 verbal conflict | 2,602,401 |
| `15` | Exhibit force posture | 4 material conflict | 1,006,668 |
| `16` | Reduce relations | 4 material conflict | 2,537,136 |
| `17` | Coerce | 4 material conflict | 12,050,785 |
| `18` | Assault | 4 material conflict | 3,963,797 |
| `19` | Fight | 4 material conflict | 16,641,694 |
| `20` | Use unconventional mass violence | 4 material conflict | 97,798 |

Quad classes as the corpus assigns them (column 30), verified by cross-tabulation: 01–05 verbal cooperation, 06–09 material cooperation, 10–14 verbal conflict, 15–20 material conflict. So `-r '1[5-9]|20'` is all material conflict. A handful of rows carry a malformed root (`--`, `X`, blank); no `-r` value matches them.

The three-digit codes under each root (e.g. `145` violent protest, `193` fight with small arms) are the CODE column of the output; the full list of 310 is GDELT's `CAMEO.eventcodes.txt`.

## `-c CC` — actor country

Matched against each actor's country field (Actor1CountryCode, Actor2CountryCode) **and** the first
three letters of each actor's code (Actor1Code, Actor2Code). GDELT fills the country field unevenly,
and the actor code is where the country is reliably written — `NGAGOV`, `ROU`, `TWNMIL`.

### Caveats

- **Romania is `ROU`, not `ROM`.** GDELT's lookup says `ROM`, but the coder writes `ROU` and leaves the
  country field blank. `-c ROU` finds 10,973 events in 1995; `-c ROM` finds 129.
- **Taiwan (`TWN`)** has its country field blank in older years; `-c TWN` now finds it through the actor
  code (13,394 events in 1995, none before the fix).
- **A three-letter actor type also matches** where the actor has no country: `-c GOV` finds
  governments that GDELT did not attach to a country, not every government. Types are in GDELT's
  `CAMEO.type.txt` (`GOV`, `MIL`, `COP`, `REB`, `OPP`, …).
- **South Sudan is `SSD`**, used 33,534 times but absent from GDELT's lookup.
- **Never used as an actor country** in the scanned data, though listed: `ALA` Aland Islands, `ANT` Netherlands Antilles, `ASM` American Samoa, `BAG` Baghdad, `BIH` Bosnia and Herzegovina, `CEU` Central Europe, `CFR` Central Africa, `EIN` East Indies, `ESH` Western Sahara, `FLK` Falkland Islands, `FRO` Faeroe Islands, `GIB` Gibraltar, `GLP` Guadeloupe, `GRL` Greenland, `GUF` French Guiana, `GUM` Guam, `GZS` Gaza Strip, `IMY` Isle of Man, `MDT` Mediterranean, `MNP` Northern Mariana Islands, `MSR` Montserrat, `MTN` Montenegro, `MTQ` Martinique, `MYT` Mayotte, `NCL` New Caledonia, `NFK` Norfolk Island, `NIU` Niue, `PCN` Pitcairn, `PYF` French Polynesia, `REU` Réunion, `SJM` Svalbard and Jan Mayen Islands, `SPM` Saint Pierre and Miquelon, `SVN` Slovenia, `TCA` Turks and Caicos Islands, `TKL` Tokelau, `VGB` British Virgin Islands, `VIR` United States Virgin Islands, `WSB` West Bank. Notably Bosnia and Slovenia — the actor dictionary has no entry for them (1995 has only the ethnic code `bos`). Their events are reachable through the place fields: `search_events.sh bosnia`.
- **Regional codes** (`AFR`, `MEA`, `WST`, …) are actors like "African leaders" or "the West"; `-c AFR` does not include Nigeria.
- An actor with no country — `GOVERNMENT`, `POLICE`, `PROTESTER` — carries no country anywhere. Many events have one actor like this; `-c` then matches on the other actor only.

### Regions and sub-national

| code | label | actor slots |
|---|---|---:|
| `WSB` | West Bank | 0 |
| `BAG` | Baghdad | 0 |
| `GZS` | Gaza Strip | 0 |
| `AFR` | Africa | 3,655,539 |
| `ASA` | Asia | 28,459 |
| `BLK` | Balkans | 9 |
| `CRB` | Caribbean | 14,047 |
| `CAU` | Caucasus | 198 |
| `CFR` | Central Africa | 0 |
| `CAS` | Central Asia | 17,515 |
| `CEU` | Central Europe | 0 |
| `EIN` | East Indies | 0 |
| `EAF` | Eastern Africa | 9,796 |
| `EEU` | Eastern Europe | 165 |
| `EUR` | Europe | 3,823,629 |
| `LAM` | Latin America | 1,869 |
| `MEA` | Middle East | 236,537 |
| `MDT` | Mediterranean | 0 |
| `NAF` | North Africa | 641 |
| `NMR` | North America | 185,331 |
| `PGS` | Persian Gulf | 86,263 |
| `SCN` | Scandinavia | 1,562 |
| `SAM` | South America | 3,781 |
| `SAS` | South Asia | 137,886 |
| `SEA` | Southeast Asia | 611,100 |
| `SAF` | Southern Africa | 63,721 |
| `WAF` | West Africa | 76,170 |
| `WST` | The West | 989,413 |

### Countries and territories

| code | label | actor slots |
|---|---|---:|
| `AFG` | Afghanistan | 5,016,507 |
| `ALA` | Aland Islands | 0 |
| `ALB` | Albania | 703,914 |
| `DZA` | Algeria | 549,052 |
| `ASM` | American Samoa | 0 |
| `AND` | Andorra | 4,806 |
| `AGO` | Angola | 589,288 |
| `AIA` | Anguilla | 5,642 |
| `ATG` | Antigua and Barbuda | 33,991 |
| `ARG` | Argentina | 701,506 |
| `ARM` | Armenia | 1,047,605 |
| `ABW` | Aruba | 20,034 |
| `AUS` | Australia | 4,834,265 |
| `AUT` | Austria | 679,579 |
| `AZE` | Azerbaijan | 1,092,097 |
| `BHS` | Bahamas | 204,830 |
| `BHR` | Bahrain | 492,706 |
| `BGD` | Bangladesh | 931,317 |
| `BRB` | Barbados | 65,549 |
| `BLR` | Belarus | 670,245 |
| `BEL` | Belgium | 1,044,058 |
| `BLZ` | Belize | 94,892 |
| `BEN` | Benin | 87,160 |
| `BMU` | Bermuda | 127,683 |
| `BTN` | Bhutan | 82,076 |
| `BOL` | Bolivia | 260,126 |
| `BIH` | Bosnia and Herzegovina | 0 |
| `BWA` | Botswana | 203,697 |
| `BRA` | Brazil | 1,080,278 |
| `VGB` | British Virgin Islands | 0 |
| `BRN` | Brunei Darussalam | 137,186 |
| `BGR` | Bulgaria | 785,574 |
| `BFA` | Burkina Faso | 96,966 |
| `BDI` | Burundi | 203,554 |
| `KHM` | Cambodia | 765,185 |
| `CMR` | Cameroon | 153,590 |
| `CAN` | Canada | 4,789,081 |
| `CPV` | Cape Verde | 31,025 |
| `CYM` | Cayman Islands | 40,340 |
| `CAF` | Central African Republic | 95,663 |
| `TCD` | Chad | 285,076 |
| `CHL` | Chile | 495,161 |
| `CHN` | China | 9,568,735 |
| `COL` | Columbia | 963,523 |
| `COM` | Comoros | 34,198 |
| `COK` | Cook Islands | 18,312 |
| `CRI` | Costa Rica | 175,809 |
| `HRV` | Croatia | 822,012 |
| `CUB` | Cuba | 1,196,873 |
| `CYP` | Cyprus | 578,896 |
| `CZE` | Czech Republic | 780,078 |
| `COD` | Democratic Republic of the Congo | 481,237 |
| `DNK` | Denmark | 596,323 |
| `DJI` | Djibouti | 111,867 |
| `DMA` | Dominica | 18,713 |
| `DOM` | Dominican Republic | 147,459 |
| `TMP` | East Timor | 190,332 |
| `ECU` | Ecuador | 278,250 |
| `EGY` | Egypt | 3,468,535 |
| `SLV` | El Salvador | 249,282 |
| `GNQ` | Equatorial Guinea | 42,584 |
| `ERI` | Eritrea | 225,671 |
| `EST` | Estonia | 235,935 |
| `ETH` | Ethiopia | 761,325 |
| `FRO` | Faeroe Islands | 0 |
| `FLK` | Falkland Islands | 0 |
| `FJI` | Fiji | 314,721 |
| `FIN` | Finland | 449,399 |
| `FRA` | France | 5,526,341 |
| `GUF` | French Guiana | 0 |
| `PYF` | French Polynesia | 0 |
| `GAB` | Gabon | 71,667 |
| `GMB` | Gambia | 151,904 |
| `GEO` | Georgia | 72,919 |
| `DEU` | Germany | 4,215,051 |
| `GHA` | Ghana | 879,396 |
| `GIB` | Gibraltar | 0 |
| `GRC` | Greece | 1,470,751 |
| `GRL` | Greenland | 0 |
| `GRD` | Grenada | 149,802 |
| `GLP` | Guadeloupe | 0 |
| `GUM` | Guam | 0 |
| `GTM` | Guatemala | 221,706 |
| `GIN` | Guinea | 160,069 |
| `GNB` | Guinea-Bissau | 65,104 |
| `GUY` | Guyana | 135,215 |
| `HTI` | Haiti | 529,575 |
| `HND` | Honduras | 261,237 |
| `HKG` | Hong Kong | 10,634 |
| `HUN` | Hungary | 656,929 |
| `ISL` | Iceland | 92,239 |
| `IND` | India | 3,134,022 |
| `IDN` | Indonesia | 1,954,479 |
| `IRN` | Iran | 6,168,565 |
| `IRQ` | Iraq | 5,332,067 |
| `IRL` | Ireland | 1,742,252 |
| `IMY` | Isle of Man | 0 |
| `ISR` | Israel | 8,268,434 |
| `ITA` | Italy | 2,660,582 |
| `CIV` | Ivory Coast | 310,339 |
| `JAM` | Jamaica | 395,798 |
| `JPN` | Japan | 4,278,665 |
| `JOR` | Jordan | 1,672,871 |
| `KAZ` | Kazakhstan | 492,139 |
| `KEN` | Kenya | 1,588,913 |
| `KIR` | Kiribati | 16,711 |
| `KWT` | Kuwait | 730,721 |
| `KGZ` | Kyrgyzstan | 397,548 |
| `LAO` | Laos | 191,117 |
| `LVA` | Latvia | 249,803 |
| `LBN` | Lebanon | 2,341,284 |
| `LSO` | Lesotho | 70,550 |
| `LBR` | Liberia | 420,405 |
| `LBY` | Libya | 1,772,251 |
| `LIE` | Liechtenstein | 15,842 |
| `LTU` | Lithuania | 313,513 |
| `LUX` | Luxembourg | 128,141 |
| `MAC` | Macao | 28,400 |
| `MKD` | Macedonia | 404,513 |
| `MDG` | Madagascar | 82,213 |
| `MWI` | Malawi | 195,470 |
| `MYS` | Malaysia | 1,572,759 |
| `MDV` | Maldives | 356,729 |
| `MLI` | Mali | 256,693 |
| `MLT` | Malta | 254,346 |
| `MHL` | Marshall Islands | 22,957 |
| `MTQ` | Martinique | 0 |
| `MRT` | Mauritania | 110,451 |
| `MUS` | Mauritius | 66,098 |
| `MYT` | Mayotte | 0 |
| `MEX` | Mexico | 1,721,093 |
| `FSM` | Micronesia | 142,664 |
| `MDA` | Moldova | 211,366 |
| `MCO` | Monaco | 153,249 |
| `MNG` | Mongolia | 145,464 |
| `MTN` | Montenegro | 0 |
| `MSR` | Montserrat | 0 |
| `MAR` | Morocco | 466,764 |
| `MOZ` | Mozambique | 331,675 |
| `MMR` | Myanmar | 916,042 |
| `NAM` | Namibia | 364,021 |
| `NRU` | Nauru | 18,716 |
| `NPL` | Nepal | 640,510 |
| `NLD` | Netherlands | 1,119,534 |
| `ANT` | Netherlands Antilles | 0 |
| `NCL` | New Caledonia | 0 |
| `NZL` | New Zealand | 1,259,067 |
| `NIC` | Nicaragua | 306,768 |
| `NER` | Niger | 156,106 |
| `NGA` | Nigeria | 3,206,468 |
| `NIU` | Niue | 0 |
| `NFK` | Norfolk Island | 0 |
| `PRK` | North Korea | 1,667,653 |
| `MNP` | Northern Mariana Islands | 0 |
| `NOR` | Norway | 634,109 |
| `PSE` | Occupied Palestinian Territory | 4,359,367 |
| `OMN` | Oman | 280,361 |
| `PAK` | Pakistan | 5,715,049 |
| `PLW` | Palau | 23,694 |
| `PAN` | Panama | 235,160 |
| `PNG` | Papua New Guinea | 115,565 |
| `PRY` | Paraguay | 101,374 |
| `COG` | People's Republic of the Congo | 186,499 |
| `PER` | Peru | 486,292 |
| `PHL` | Philippines | 2,554,548 |
| `PCN` | Pitcairn | 0 |
| `POL` | Poland | 1,346,147 |
| `PRT` | Portugal | 517,975 |
| `PRI` | Puerto Rico | 72 |
| `QAT` | Qatar | 729,663 |
| `ROU` | Romania *(what the corpus uses; not in GDELT's lookup)* | 10,973 in 1995 alone |
| `ROM` | Romania — *use `ROU`* | 9,586 |
| `RUS` | Russia | 9,672,195 |
| `RWA` | Rwanda | 578,051 |
| `REU` | Réunion | 0 |
| `SHN` | Saint Helena | 3,012 |
| `KNA` | Saint Kitts-Nevis | 49,728 |
| `LCA` | Saint Lucia | 34,648 |
| `SPM` | Saint Pierre and Miquelon | 0 |
| `VCT` | Saint Vincent and the Grenadines | 36,356 |
| `WSM` | Samoa | 37,058 |
| `SMR` | San Marino | 4,945 |
| `STP` | Sao Tome and Principe | 25,777 |
| `SAU` | Saudi Arabia | 2,160,081 |
| `SEN` | Senegal | 196,866 |
| `SRB` | Serbia | 529,495 |
| `SYC` | Seychelles | 201,425 |
| `SLE` | Sierra Leone | 257,879 |
| `SGP` | Singapore | 696,161 |
| `SVK` | Slovakia | 420,084 |
| `SVN` | Slovenia | 0 |
| `SLB` | Solomon Islands | 67,814 |
| `SOM` | Somalia | 1,093,923 |
| `ZAF` | South Africa | 1,298,842 |
| `KOR` | South Korea | 2,209,773 |
| `ESP` | Spain | 1,872,766 |
| `LKA` | Sri Lanka | 1,102,282 |
| `SDN` | Sudan | 1,579,776 |
| `SUR` | Suriname | 26,721 |
| `SJM` | Svalbard and Jan Mayen Islands | 0 |
| `SWZ` | Swaziland | 86,587 |
| `SWE` | Sweden | 719,871 |
| `CHE` | Switzerland | 1,228,565 |
| `SYR` | Syria | 3,517,079 |
| `TWN` | Taiwan | 166,781 |
| `TJK` | Tajikistan | 405,798 |
| `TZA` | Tanzania | 448,865 |
| `THA` | Thailand | 1,564,989 |
| `TGO` | Togo | 100,900 |
| `TKL` | Tokelau | 0 |
| `TON` | Tonga | 42,546 |
| `TTO` | Trinidad and Tobago | 135,116 |
| `TUN` | Tunisia | 490,136 |
| `TUR` | Turkey | 3,932,477 |
| `TKM` | Turkmenistan | 260,152 |
| `TCA` | Turks and Caicos Islands | 0 |
| `TUV` | Tuvalu | 10,704 |
| `UGA` | Uganda | 1,249,567 |
| `UKR` | Ukraine | 1,570,583 |
| `ARE` | United Arab Emirates | 914,353 |
| `GBR` | United Kingdom | 10,537,653 |
| `USA` | United States | 66,742,883 |
| `VIR` | United States Virgin Islands | 0 |
| `URY` | Uruguay | 122,290 |
| `UZB` | Uzbekistan | 378,148 |
| `VUT` | Vanuatu | 31,265 |
| `VAT` | Vatican City | 287,827 |
| `VEN` | Venezuela | 790,865 |
| `VNM` | Vietnam | 1,361,044 |
| `WLF` | Wallis and Futuna Islands | 430 |
| `ESH` | Western Sahara | 0 |
| `YEM` | Yemen | 907,227 |
| `ZMB` | Zambia | 611,546 |
| `ZWE` | Zimbabwe | 1,081,496 |
| `SSD` | South Sudan *(not in GDELT's lookup)* | 33,534 |
