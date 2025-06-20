const fs = require('fs');
var summerFiles = fs.readdirSync('summerFiles');
var tdfFiles = summerFiles.filter(x => x.toLowerCase().indexOf('stim') == -1);

for(let tdfFileName of tdfFiles){
    console.log(tdfFileName);
    var newTdfFileName = tdfFileName.replace("SU_2021","FA_2021");
    var tdf = fs.readFileSync('summerFiles/'+tdfFileName, 'utf-8');
    var tdfJSON = JSON.parse(tdf);
    var stimFileName = tdfJSON.tutor.setspec[0].stimulusfile[0];
    var newStimFileName = stimFileName.replace("SU_2021","FA_2021");
    tdfJSON.tutor.setspec[0].stimulusfile[0] = newStimFileName;
    var stim = fs.readFileSync('summerFiles/'+stimFileName, 'utf-8');
    var stimJSON = JSON.parse(stim);
    const numClusters = stimJSON.setspec.clusters.length;
    const finalStimIndex = numClusters - 1;
    delete tdfJSON.tutor.generatedtdfs;
    tdfJSON.tutor.unit[1].assessmentsession[0].clusterlist[0] = "" + finalStimIndex.toString() + "-" + finalStimIndex.toString();
    tdfJSON.tutor.unit[2].learningsession[0].clusterlist[0] = "0-" + (finalStimIndex-1).toString();

    let tdfData = JSON.stringify(tdfJSON, null, 4);
    console.log("writing file: ", newTdfFileName);
    fs.writeFileSync("summerFiles_regular/"+newTdfFileName, tdfData);
    let stimData = JSON.stringify(stimJSON, null, 4);
    fs.writeFileSync("summerFiles_regular/"+newStimFileName, stimData);
}

console.log("done!");
