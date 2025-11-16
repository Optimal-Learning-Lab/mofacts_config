const fs = require('fs');

let summerFiles = ["Chapter_10_ambanker_2020_11_11T15_34_31_278Z_SP_2021_Stim.json","Chapter_10_ambanker_2020_11_11T15_34_31_278Z_SP_2021_TDF.xml","Chapter_14_ambanker_2020_10_19T20_56_08_150Z_SP_2021_Stim.json","Chapter_14_ambanker_2020_10_19T20_56_08_150Z_SP_2021_TDF.xml","Chapter_15_ambanker_2020_10_19T21_01_26_470Z_SP_2021_Stim.json","Chapter_15_ambanker_2020_10_19T21_01_26_470Z_SP_2021_TDF.xml","Chapter_19_ambanker_2020_10_09T15_16_38_309Z_SP_2021_Stim.json","Chapter_19_ambanker_2020_10_09T15_16_38_309Z_SP_2021_TDF.xml","Chapter_7_ambanker_2020_10_14T19_52_13_812Z_SP_2021_Stim.json","Chapter_7_ambanker_2020_10_14T19_52_13_812Z_SP_2021_TDF.xml","Chapter_8_ambanker_2020_10_14T19_55_11_590Z_SP_2021_Stim.json","Chapter_8_ambanker_2020_10_14T19_55_11_590Z_SP_2021_TDF.xml","Chapter_9_ambanker_2020_10_26T14_29_30_552Z_SP_2021_Stim.json","Chapter_9_ambanker_2020_10_26T14_29_30_552Z_SP_2021_TDF.xml","SP_2021_ch10_10-stim.json","SP_2021_ch1_10-stim.json","SP_2021_ch11_10-stim.json","SP_2021_ch12_10-stim.json","SP_2021_ch13_10-stim.json","SP_2021_ch14_10-stim.json","SP_2021_ch15_10-stim.json","SP_2021_ch16_10-stim.json","SP_2021_ch17_10-stim.json","SP_2021_ch18_10-stim.json","SP_2021_ch19_10-stim.json","SP_2021_ch20_10-stim.json","SP_2021_ch2_10-stim.json","SP_2021_ch21_10-stim.json","SP_2021_ch22_10-stim.json","SP_2021_ch23_10-stim.json","SP_2021_ch24_10-stim.json","SP_2021_ch3_10-stim.json","SP_2021_ch4_10-stim.json","SP_2021_ch5_10-stim.json","SP_2021_ch6_10-stim.json","SP_2021_ch7_10-stim.json","SP_2021_ch8_10-stim.json","SP_2021_ch9_10-stim.json","SP_2021IESch10_10_percent.xml","SP_2021IESch1_10_percent.xml","SP_2021IESch11_10_percent.xml","SP_2021IESch12_10_percent.xml","SP_2021IESch13_10_percent.xml","SP_2021IESch14_10_percent.xml","SP_2021IESch15_10_percent.xml","SP_2021IESch16_10_percent.xml","SP_2021IESch17_10_percent.xml","SP_2021IESch18_10_percent.xml","SP_2021IESch19_10_percent.xml","SP_2021IESch20_10_percent.xml","SP_2021IESch2_10_percent.xml","SP_2021IESch21_10_percent.xml","SP_2021IESch22_10_percent.xml","SP_2021IESch23_10_percent.xml","SP_2021IESch24_10_percent.xml","SP_2021IESch3_10_percent.xml","SP_2021IESch4_10_percent.xml","SP_2021IESch5_10_percent.xml","SP_2021IESch6_10_percent.xml","SP_2021IESch7_10_percent.xml","SP_2021IESch8_10_percent.xml","SP_2021IESch9_10_percent.xml"];
let summerFiles2 = ["Chapter_6-_Banker_ambanker_2020_06_04T00_24_58_668Z_SU_2020_TDF.xml","Chapter_6-_Banker_ambanker_2020_06_04T00_24_58_668Z_SU_2020_Stim.json","Chapter_5-_Banker_ambanker_2020_06_04T00_24_42_562Z_SU_2020_TDF.xml","Chapter_5-_Banker_ambanker_2020_06_04T00_24_42_562Z_SU_2020_Stim.json","Chapter_3-Banker_ambanker_2020_06_04T00_24_27_093Z_SU_2020_TDF.xml","Chapter_3-Banker_ambanker_2020_06_04T00_24_27_093Z_SU_2020_Stim.json","Chapter_2-_Banker_ambanker_2020_06_04T00_15_19_652Z_SU_2020_TDF.xml","Chapter_2-_Banker_ambanker_2020_06_04T00_15_19_652Z_SU_2020_Stim.json","Chapter_11-A.Banker_ambanker_2020_06_24T19_35_47_939Z_SU_2020_TDF.xml","Chapter_11-A.Banker_ambanker_2020_06_24T19_35_47_939Z_SU_2020_Stim.json","Chapter_12-A.Banker_ambanker_2020_06_24T19_36_04_932Z_SU_2020_TDF.xml","Chapter_12-A.Banker_ambanker_2020_06_24T19_36_04_932Z_SU_2020_Stim.json","Chapter_13-_Banker_ambanker_2020_06_04T00_25_17_033Z_SU_2020_TDF.xml","Chapter_13-_Banker_ambanker_2020_06_04T00_25_17_033Z_SU_2020_Stim.json","Chapter_16_Banker_ambanker_2020_06_17T14_12_48_512Z_SU_2020_TDF.xml","Chapter_16_Banker_ambanker_2020_06_17T14_12_48_512Z_SU_2020_Stim.json","Chapter_17-_A.Banker_ambanker_2020_06_24T19_30_03_863Z_SU_2020_TDF.xm","Chapter_17-_A.Banker_ambanker_2020_06_24T19_30_03_863Z_SU_2020_Stim.json","Chapter_20-A.Banker_ambanker_2020_06_24T19_30_56_157Z_SU_2020_TDF.xml","Chapter_20-A.Banker_ambanker_2020_06_24T19_30_56_157Z_SU_2020_Stim.json","Chapter_21-A.Banker_ambanker_2020_06_24T19_34_16_477Z_SU_2020_TDF.xml","Chapter_21-A.Banker_ambanker_2020_06_24T19_34_16_477Z_SU_2020_Stim.json","Chapter_22-_Banker_ambanker_2020_06_04T00_25_56_539Z_SU_2020_TDF.xml","Chapter_22-_Banker_ambanker_2020_06_04T00_25_56_539Z_SU_2020_Stim.json"]

var tdfs = fs.readFileSync('SP_2021_Tdfs.json', 'utf-8');
var tdfsJSON = JSON.parse(tdfs);
var tdfStream = fs.createWriteStream("SU_2021_Tdfs.json", {flags:'a'});
tdfStream.write('[');
for(let i=0;i<tdfsJSON.length;i++){
    let tdf = tdfsJSON[i];
    
    if(summerFiles2.findIndex(x => x===tdf.fileName)!=-1){
        tdf.fileName = tdf.fileName.replace("SU_2020","SU_2021");
        tdf.tdfs.tutor.setspec[0].stimulusfile = [tdf.tdfs.tutor.setspec[0].stimulusfile[0].replace("SU_2020","SU_2021")];
        tdfStream.write(JSON.stringify(tdf));
        if(i<tdfsJSON.length-1){
            tdfStream.write(',');
        }
    }
}
tdfStream.write(']');
tdfStream.end();

console.log("done with tdfs")

var stim = fs.readFileSync('SP_2021_Stimuli.json')
var stimJSON = JSON.parse(stim);
var stimStream = fs.createWriteStream("SU_2021_Stimuli.json", {flags:'a'});
stimStream.write('[');
for(let j=0;j<stimJSON.length;j++){
    let stim = stimJSON[j];
    
    if(summerFiles2.findIndex(x => x===stim.fileName)!=-1){
        console.log('working',stim.fileName);
        stim.fileName = stim.fileName.replace("SU_2020","SU_2021");
        stimStream.write(JSON.stringify(stim));
        if(j<stimJSON.length-1){
            stimStream.write(',');
        }
    }
};
stimStream.write(']');
stimStream.end();