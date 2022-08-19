const fs = require('fs');
var tdfs = fs.readFileSync('tdfs.json', 'utf-8');
var tdfsJSON = JSON.parse(tdfs);

for(let tdf of tdfsJSON){
    let fileName = tdf.fileName;//.replace("SP_2021","SU_2021");
    let tdfData = JSON.stringify(tdf.tdfs);//.replace("SP_2021","SU_2021");
    console.log("writing file: ", fileName);
    fs.writeFileSync("all/"+fileName, tdfData);
}

var stims = fs.readFileSync('stimuli.json','utf-8');
var stimsJSON = JSON.parse(stims);

for(let stim of stimsJSON){
    let fileName = stim.fileName;//.replace("SP_2021","SU_2021");
    let stimData = JSON.stringify(stim.stimuli);//.replace("SP_2021","SU_2021");
    console.log("writing file: ",fileName);
    fs.writeFileSync("all/"+fileName, stimData);
}
console.log("done!");
