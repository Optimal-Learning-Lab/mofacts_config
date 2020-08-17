
// TODO: we should reformat tags to be arrays like xml2json (each tag value is an array)
// also convert actual values to strings like xml2json
var fs = require('fs');
const CURRENT_SEMESTER = 'FA_2020';

for(var i=1;i<25;i++){
    for(var compressionLevel of ['05','10','15']){
        var filename = "FA_2020/Generated_Clozes/ch" + i + "." + compressionLevel + ".selected-cloze.json";
        var resultFilePath = "FA_2020/Stims/" + CURRENT_SEMESTER + "_" + "ch" + i + "_" + compressionLevel + "-stim.json";
        var resultFilename = CURRENT_SEMESTER + "_" + "ch" + i + "_" + compressionLevel + "-stim.json";
        console.log("filename: " + filename);
        console.log("resultFilename: " + resultFilename);
        fs.readFile(filename, 'utf8', (function(filename,resultFilePath,resultFilename){return function(err, data) {
            if (err) throw err;
            var result = JSON.parse(data);
            console.log(filename);
            var stimJSON = getStimFromClozes(result,resultFilename)
            fs.writeFile(resultFilePath,JSON.stringify(stimJSON,null,4),function(err,file){
                if(err) throw err;
                console.log(filename + " done!");
            })
        }
        })
        (filename,resultFilePath, resultFilename));
    }
}

function getStimFromClozes(result,filename){
    sentenceIDtoSentenceMap = {};
    clozeIDToClozeMap = {};
    sentenceIDtoClozesMap = {};
    
    var sentences = result.sentences;
    var clozes = result.clozes;
    for(var cloze of clozes){
      cloze.unitIndex = 0;
    }
    
    for(var sentenceIndex in sentences){
        var sentence = sentences[sentenceIndex];
        var sentenceID = parseInt(sentence.itemId);
        sentenceIDtoSentenceMap[sentenceID] = sentence;
    }

    for(var cloze of clozes){
        clozeIDToClozeMap[cloze.clozeId] = cloze;
        var sentenceID = cloze.itemId;
        if(!sentenceIDtoClozesMap[sentenceID]){
            sentenceIDtoClozesMap[sentenceID] = [];
        }
        sentenceIDtoClozesMap[sentenceID].push(cloze);
    }
    
    var templateStimJSON = {
        "fileName" : "",
        "stimuli" : {
            "setspec" : {
                "clusters" : []
            }
        },
        "owner" : "",
        "source" : "content_generation",
        "sourceSentences": sentences
    }
    
    var curStim = JSON.parse(JSON.stringify(templateStimJSON));
    var completedSentenceIDs = {};
    for(var index in clozes){
        var sentenceID = clozes[index].itemId;

        if(!completedSentenceIDs[sentenceID]){
            let cluster = {"stims":[]};
            let curSentenceClozes = sentenceIDtoClozesMap[sentenceID];
            for(var index2 in curSentenceClozes){
                let cloze = curSentenceClozes[index2];
                let stim = {
                    "response": {
                        "correctResponse": "",
                    },
                    "display": {
                        "clozeText": ""
                    },
                    "parameter": "0,.7",
                    "tags": {}
                };
                stim.display.clozeText  = cloze.cloze;
                stim.response.correctResponse = cloze.correctResponse;
                stim.tags = {...cloze.tags};
                stim.tags['itemId'] = cloze.itemId;
                stim.tags['clozeId'] = cloze.clozeId;

                if(cloze.tags.clozeCorefTransformation){
                    stim.tags.originalItem = JSON.parse(JSON.stringify(stim.display.clozeText));
                    stim.display.clozeText = cloze.tags.clozeCorefTransformation;

                    if(cloze.tags.correctResponseCorefTransformation){
                        if(cloze.tags.correctResponseCorefTransformation != stim.response.correctResponse){
                            stim.tags.originalCorrectResponse = JSON.parse(JSON.stringify(stim.response.correctResponse));
                            stim.response.correctResponse = cloze.tags.correctResponseCorefTransformation;
                        }else{
                            delete stim.tags.correctResponseCorefTransformation;
                        }                    
                    }
                }else if(cloze.tags.clozeParaphraseTransformation){
                    stim.alternateDisplays = [{"clozeText": cloze.tags.clozeParaphraseTransformation}];
                }
                
                cluster.stims.push(stim);
            }
            curStim.stimuli.setspec.clusters.push(cluster);
            completedSentenceIDs[sentenceID] = true;
        }
    }
    
    curStim.fileName = filename;
    curStim.owner = "fill me in"

    return curStim;
}



