
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
    let isEven = parseInt(filename.split('_')[2].substring(2)) % 2 == 0;
    let parameter = isEven ? "0,.72" : "0,.82";
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
                    "parameter": parameter,
                    "tags": {}
                };
                stim.display.clozeText  = cloze.cloze;
                stim.response.correctResponse = cloze.correctResponse;
                stim.tags = {...cloze.tags};
                stim.tags['itemId'] = cloze.itemId;
                stim.tags['clozeId'] = cloze.clozeId;

                if(stim.tags.clozeCorefTransformation && 
                    (stim.tags.clozeCorefTransformation != stim.display.clozeText)){

                    if(stim.tags.clozeCorefTransformation != stim.display.clozeText){
                        stim.tags.originalItem = JSON.parse(JSON.stringify(stim.display.clozeText));
                        stim.display.clozeText = stim.tags.clozeCorefTransformation;

                        if(stim.tags.correctResponseCorefTransformation){
                            if(cloze.tags.correctResponseCorefTransformation != stim.response.correctResponse){
                                stim.tags.originalCorrectResponse = JSON.parse(JSON.stringify(stim.response.correctResponse));
                                stim.response.correctResponse = stim.tags.correctResponseCorefTransformation;
                            }else{
                                delete stim.tags.correctResponseCorefTransformation;
                            }                    
                        }
                    }
                }else{
                    if(stim.tags.clozeParaphraseTransformation){
                        if(stim.tags.clozeParaphraseTransformation != stim.display.clozeText){
                            stim.alternateDisplays = [{"clozeText": stim.tags.clozeParaphraseTransformation}];
                        }else{
                            delete stim.tags.clozeParaphraseTransformation;
                        }
                    }

                    delete stim.tags.clozeCorefTransformation;
                    delete stim.tags.correctResponseCorefTransformation;
                } 

                cluster.stims.push(stim);
            }
            curStim.stimuli.setspec.clusters.push(cluster);
            completedSentenceIDs[sentenceID] = true;
        }
    }

    curStim.stimuli.setspec.clusters.push({
        "stims" : [ 
            {
                "response" : {
                    "correctResponse" : "Yes~Excellent this should make the practice more effective.;.*~That may not be the best choice. We suggest going back and reading the chapter. "
                },
                "display" : {
                    "clozeText" : "Did you read the chapter (yes/no)?"
                },
                "parameter" : "0,.72"
            }
        ]
    });
    
    curStim.fileName = filename;
    curStim.owner = "jEdm7We6sQXB3x3Y3"

    return curStim;
}



