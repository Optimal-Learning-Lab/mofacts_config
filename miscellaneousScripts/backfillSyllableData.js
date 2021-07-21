var syllableTdfs = [
    "BIOL_2010_ambanker_2019_11_06T14_01_56_017Z_TDF_xml", 
    "Chapter_11_ambanker_2020_04_22T21_04_41_317Z_SP_2020_TDF_xml", 
    "Rothschild-Chapter2_mrothschild_2020_09_09T21_22_43_491Z_FA_2020_TDF_xml", 
    "Banker:_Chapter_1_ambanker_2020_08_26T15_43_06_096Z_FA_2020_TDF_xml", 
    "Chapter_2_ambanker_2020_09_16T14_11_55_913Z_FA_2020_TDF_xml", 
    "Chapter_3_ambanker_2020_09_16T14_20_50_630Z_FA_2020_TDF_xml", 
    "Chapter_1_ambanker_2021_02_24T15_03_15_768Z_SP_2021_TDF_xml", 
    "Chapter_2_ambanker_2021_02_24T15_03_49_837Z_SP_2021_TDF_xml", 
    "Chapter_3_ambanker_2021_02_24T15_04_09_436Z_SP_2021_TDF_xml", 
    "Banker:_Chapter_13_ambanker_2020_08_26T15_27_25_408Z_SP_2021_TDF_xml", 
    "Chapter_22_ambanker_2020_09_16T14_35_02_727Z_SP_2021_TDF_xml", 
    "Chapter_17_ambanker_2020_11_11T15_41_17_634Z_SP_2021_TDF_xml", 
    "Chapter_19_ambanker_2020_10_09T15_16_38_309Z_SP_2021_TDF_xml", 
    "Chapter_5_ambanker_2021_02_24T15_04_32_954Z_SP_2021_TDF_xml", 
    "Chapter_14_ambanker_2020_10_19T20_56_08_150Z_SP_2021_TDF_xml", 
    "Chapter_7_ambanker_2021_02_24T15_05_08_864Z_SP_2021_TDF_xml", 
    "Chapter_8_ambanker_2021_02_24T15_05_36_123Z_SP_2021_TDF_xml", 
    "Chapter_9_ambanker_2021_02_24T15_05_55_649Z_SP_2021_TDF_xml", 
    "Chapter_10_ambanker_2021_02_24T15_06_11_642Z_SP_2021_TDF_xml", 
    "Chapter_6_ambanker_2021_02_24T15_04_51_796Z_SP_2021_TDF_xml", 
    "Chapter_11_ambanker_2021_02_24T15_06_33_763Z_SP_2021_TDF_xml", 
    "Chapter_12_ambanker_2021_02_24T15_06_51_782Z_SP_2021_TDF_xml", 
    "Chapter_15_ambanker_2020_10_19T21_01_23_717Z_SP_2021_TDF_xml", 
    "Chapter_16_ambanker_2020_11_09T03_42_56_411Z_SP_2021_TDF_xml", 
    "Chapter_21_ambanker_2020_12_03T04_19_20_659Z_SP_2021_TDF_xml", 
    "Chapter_20_ambanker_2020_12_03T04_20_32_769Z_SP_2021_TDF_xml", 
]

var syllableStims = [];
var syllableStimsData = {};

var errorLog = [];

for(var tdf of syllableTdfs){
    var tdfName = tdf.replace("_xml",".xml");
    var tdfData = db.getCollection('tdfs').findOne({fileName:tdfName});
    if(!tdfData){
        tdfData = db.getCollection('tdfs').findOne({fileName:tdfName.replace("FA_2020","SP_2021")});
        if(!tdfData){
            tdfData = db.getCollection('tdfs').findOne({fileName:tdfName.replace("SP_2021","SU_2021")});
            if(!tdfData){
                errorLog.push("no tdf data:",tdfName);
                continue;
            }
        }
    }
    var tdfStimFile = tdfData.tdfs.tutor.setspec[0].stimulusfile[0];
    tdfStimFile = tdfStimFile.replace(".xml","_xml").replace(".json","_json");
    syllableStims.push(tdfStimFile);
    var syllables = db.getCollection('stimuli_syllables').findOne({filename:tdfStimFile});
    if(!syllables){
        syllables = db.getCollection('stimuli_syllables').findOne({filename:tdfStimFile.replace("_json","_xml")});
        if(!syllables) {
            syllables = db.getCollection('stimuli_syllables').findOne({filename:tdfStimFile.replace("SP_2021","FA_2020")});
            if(!syllables){
                syllables = db.getCollection('stimuli_syllables').findOne({filename:tdfStimFile.replace("SU_2021","SP_2021")});
                if(!syllables){
                    errorLog.push("no syllables for: ",tdfStimFile,tdfName);
                    continue;
                }
            }
        }
    }
    syllableStimsData[tdf] = syllables.data;
}

function syllableCheck(utl){ 
    var newUtl = JSON.parse(JSON.stringify(utl));
    var updated=false;
    if(!updatedTdfsLog[utl._id]) updatedTdfsLog[utl._id] = {};
    Object.keys(utl).map(function(key){ 
        var logs = [];
        var keyUpdated=false;
        if(syllableTdfs.indexOf(key)!=-1){
            var syllableData = syllableStimsData[key];
            var log = utl[key];
            var lastQuestion = undefined;
            var lastWasAnswer = false;
            for(var i=0;i<log.length;i++){
                var record = log[i];
                if(record.action==="answer" || record.action==="[timeout]"){
                    if(!lastQuestion){
                        for(var j=i;j>0;j--){
                            var otherRec = log[j];
                            if(otherRec.action==="question"){
                                lastQuestion=otherRec;
                                break;
                            }
                        }
                    }
                    if(!lastQuestion){
                        logs.push("noLastQuestion?:",lastQuestion,record,JSON.parse(JSON.stringify(i)));
                    }else{
                        var selectedAnswer = lastQuestion.selectedAnswer;
                        var originalAnswer = lastQuestion.originalAnswer;
                        var originalQuestion = lastQuestion.originalQuestion;
                        if(originalQuestion === "Did you read the chapter (yes/no)?"){
                            lastWasAnswer = true;
                            continue;
                        }
                        var syllableAnswerData = syllableData[originalAnswer];
                        if(!syllableAnswerData){
                            syllableAnswerData = syllableData[(originalAnswer || "zxzxczxcvzxcv").toLowerCase()];
                            if(!syllableAnswerData){
                                syllableAnswerData = syllableData[selectedAnswer];
                                if(!syllableAnswerData){
                                    logs.push("no syllable data: ",[record.currentAnswerSyllables=="",originalAnswer,lastQuestion,record]);
                                    continue;
                                }
                            }
                        }
                        var hadSylls = !!record.currentAnswerSyllables;
                        if(!!originalQuestion && !hadSylls){
                            newUtl[key][i]['currentAnswerSyllables'] = syllableAnswerData;
                            logs.push(JSON.parse(JSON.stringify(i)));
                            //logs.push(JSON.parse(JSON.stringify(i)),newUtl[key][i].currentAnswerSyllables,syllableAnswerData,lastQuestion,newUtl[key][i]);

                            keyUpdated = true;
                            updated=true;
                        }
                    }
                    lastWasAnswer = true;
                }else if(record.action == "question"){
                    lastQuestion = record;
                    lastWasAnswer = false;
                }else{
                    if(!lastWasAnswer){
                        lastQuestion = undefined;
                    }
                    lastWasAnswer = false;
                }
            }
        }        
        //if(keyUpdated){
            if(!updatedTdfsLog[utl._id][key]){
                updatedTdfsLog[utl._id][key] = logs.slice(0,15);
            }else{
                //updatedTdfsLog[utl._id][key] = updatedTdfsLog[utl._id][key].concat(logs);
            }
        //}
    })
    if(updated){
        updatedTdfs.push(utl._id);
        db.getCollection('userTimesLog').replaceOne({"_id":utl._id},newUtl);
    }
}

var updatedTdfs = [];
var updatedTdfsLog = {};
var haveUpdateExample = false;
var utlCursor = db.getCollection('userTimesLog').find({});
utlCursor.forEach(syllableCheck);
while(utlCursor.hasNext()){
    utlCursor.forEach(syllableCheck);
}

for(var utlKey in updatedTdfsLog){
    var utlLog = updatedTdfsLog[utlKey];
    for(var tdfKey in utlLog){
        var tdfUtlLog = utlLog[tdfKey];
        if(tdfUtlLog.length==0){
            delete utlLog[tdfKey];
        }
    }
    if(Object.keys(utlLog).length==0){
        delete updatedTdfsLog[utlKey];
    }
}

[updatedTdfs,updatedTdfsLog,errorLog];