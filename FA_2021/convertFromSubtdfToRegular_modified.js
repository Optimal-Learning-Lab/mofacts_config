const fs = require('fs');
var summerFiles = fs.readdirSync('summerFiles');
var tdfFiles = summerFiles.filter(x => x.toLowerCase().indexOf('stim') == -1);

for(let tdfFileName of tdfFiles){
    console.log(tdfFileName);
    
    // var newTdfFileName = tdfFileName.replace("SU_2021","FA_2021");
    var newTdfFileName = tdfFileName; //no replacement filename

    var tdf = fs.readFileSync('summerFiles/'+tdfFileName, 'utf-8');
    var tdfJSON = JSON.parse(tdf);
    
    if(typeof tdfJSON.tutor !== 'undefined'){
        if(typeof tdfJSON.tutor.setspec !== 'undefined'){
            if(typeof tdfJSON.tutor.setspec.stimulusfile !== 'undefined'){                
                console.log('processing...');
                var stimFileName = tdfJSON.tutor.setspec.stimulusfile;
                // var newStimFileName = stimFileName.replace("SU_2021","FA_2021");
                var newStimFileName = stimFileName; //no replacement filename
                tdfJSON.tutor.setspec.stimulusfile = newStimFileName;
                var stim = fs.readFileSync('summerFiles/'+stimFileName, 'utf-8');
                var stimJSON = JSON.parse(stim);
                const numClusters = stimJSON.setspec.clusters.length;
                const finalStimIndex = numClusters - 1;
                tdfJSON.tutor.unit[1].assessmentsession.clusterlist = "" + finalStimIndex.toString() + "-" + finalStimIndex.toString();
                tdfJSON.tutor.unit[2].learningsession.clusterlist = "0-" + (finalStimIndex-1).toString();
                } else {
                console.log('has no stimulusfile property:', tdfFileName);
            }} else {
            console.log('has no setspec property:', tdfFileName);
        } 
    }
    delete tdfJSON.tutor.generatedtdfs;
    let tdfData = JSON.stringify(tdfJSON, null, 4);
    console.log("writing file: ", newTdfFileName);
    fs.writeFileSync("summerFiles_regular/"+newTdfFileName, tdfData);
    let stimData = JSON.stringify(stimJSON, null, 4);
    fs.writeFileSync("summerFiles_regular/"+newStimFileName, stimData);
}

console.log("done!");