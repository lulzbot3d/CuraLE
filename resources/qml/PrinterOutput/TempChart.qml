// This is a chart that would display a line illustrating the rise and drop in temperatures over time for the printer
// Useful for telling at a glance how well your printer was holding temperature, but may need some refining.
// Not sure how well it can be reimplemented at present but I figured I'd get it into it's own file over here for the moment.

Canvas {
    anchors.right: parent.right
    height: width / 3
    width: base.width - 8 * UM.Theme.getSize("default_margin").width

    anchors.rightMargin: UM.Theme.getSize("default_margin").width*4
    anchors.leftMargin: UM.Theme.getSize("default_margin").width*4

    id: temperatureGraph

    antialiasing: true

    property variant nozzleTemperatureValues: [[]]
    property variant bedTemperatureValues: []
    property variant lineStyles: [Qt.rgba(1, 0, 0, 1), Qt.rgba(0, 1, 0, 1), Qt.rgba(1, 1, 0, 1), Qt.rgba(1, 0, 1, 1)]
    property variant bedLineStyle: Qt.rgba(0, 0, 1, 1)

    function updateValues() {
        var heatedBed = machineHeatedBed.properties.value == "True"
        var graphs = machineExtruderCount.properties.value
        var resolution = 60

        while(nozzleTemperatureValues.length < graphs) {
            nozzleTemperatureValues.push([])
        }

        for(var i = 0; i < graphs; i++) {
            while(nozzleTemperatureValues[i].length < resolution) {
                nozzleTemperatureValues[i].push(0)
            }

            for(var j = 0; j < resolution - 1; j++) {
                nozzleTemperatureValues[i][j] = nozzleTemperatureValues[i][j + 1]
            }
            nozzleTemperatureValues[i][resolution - 1] = printerConnected ? Math.round(connectedPrinter.hotendTemperatures[i]) : 0
        }

        if(heatedBed) {
            while(bedTemperatureValues.length < resolution) {
                bedTemperatureValues.push(0)
            }

            for(var j = 0; j < resolution - 1; j++) {
                bedTemperatureValues[j] = bedTemperatureValues[j + 1]
            }
            bedTemperatureValues[resolution - 1] = printerConnected ? Math.round(connectedPrinter.bedTemperature) : 0
        }

        requestPaint()
    }

    onPaint: {
        var ctx = temperatureGraph.getContext('2d');
        ctx.save();
        ctx.clearRect(0, 0, temperatureGraph.width, temperatureGraph.height);
        ctx.translate(0,0);
        ctx.lineWidth = 1;
        //ctx.strokeStyle = Qt.rgba(.3, .3, .3, 1);
        ctx.strokeStyle = Qt.rgba(.75, .84, .18, 1);

        // Horizontal lines
        for(var i = 0; i < 6; i++) {
            if(i > 0) {
                ctx.beginPath();
                //ctx.moveTo(0, temperatureGraph.height / 6 * i);
                ctx.moveTo(temperatureGraph.width/12, temperatureGraph.height / 6 * i);
                ctx.lineTo(temperatureGraph.width, temperatureGraph.height / 6 * i);
                ctx.closePath();
                ctx.stroke();
            }
        }

        // Very bottom line
        ctx.beginPath();
        ctx.moveTo(0, temperatureGraph.height-1);
        ctx.lineTo(temperatureGraph.width, temperatureGraph.height-1);
        ctx.closePath();
        ctx.stroke();

        // Very top line
        ctx.beginPath();
        ctx.moveTo(0, 1);
        ctx.lineTo(temperatureGraph.width, 1);
        ctx.closePath();
        ctx.stroke();

        // Vertical lineStyles
        for(var i = 0; i < 12; i++) {
            if(i > 0) {
                ctx.beginPath();
                ctx.moveTo(temperatureGraph.width / 12 * i, 0);
                ctx.lineTo(temperatureGraph.width / 12 * i, temperatureGraph.height);
                ctx.closePath();
                ctx.stroke();
            }

            else {
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(0, temperatureGraph.height);
                ctx.closePath();
                ctx.stroke();
            }
        }

        // Vertical ver right lineStyles
        ctx.beginPath();
        ctx.moveTo(temperatureGraph.width - 1, 0);
        ctx.lineTo(temperatureGraph.width - 1, temperatureGraph.height);
        ctx.closePath();
        ctx.stroke();


        for(var k = 0; k < nozzleTemperatureValues.length; k++) {
            ctx.strokeStyle = lineStyles[k];

            ctx.beginPath();
            //ctx.moveTo(0, temperatureGraph.height + 1);
            ctx.moveTo(0, temperatureGraph.height + 2);
            for(var i = 0; i < nozzleTemperatureValues[k].length; i++) {
                ctx.lineTo(i * temperatureGraph.width / (nozzleTemperatureValues[k].length - 1), temperatureGraph.height - nozzleTemperatureValues[k][i] / 300 * temperatureGraph.height);
            }
            //ctx.lineTo(temperatureGraph.width, temperatureGraph.height + 1);
            ctx.lineTo(temperatureGraph.width, temperatureGraph.height + 2);
            ctx.closePath();
            ctx.stroke();
        }

        ctx.strokeStyle = bedLineStyle;

        ctx.beginPath();
        ctx.moveTo(0, temperatureGraph.height + 1);
        for(var i = 0; i < bedTemperatureValues.length; i++) {
            ctx.lineTo(i * temperatureGraph.width / (bedTemperatureValues.length - 1), temperatureGraph.height - bedTemperatureValues[i] / 300 * temperatureGraph.height);
        }
        ctx.lineTo(temperatureGraph.width, temperatureGraph.height + 1);
        ctx.closePath();
        ctx.stroke();

        ctx.fillStyle = Qt.rgba(0, 0, 0, 1);
        ctx.fillText( 0, 2, temperatureGraph.height - 3)
        for(var i = 0; i < 5; i++) {
            ctx.fillText((5-i) * 50, 2, temperatureGraph.height / 6 * (i+1))
        }

        ctx.restore();
    }
}

// Don't know if these were part of it just came in the copy paste I guess.
// Rectangle {
//     height: UM.Theme.getSize("default_margin").height
//     width: base.width
//     color: "transparent"
// }

// UM.SettingPropertyProvider {
//     id: bedTemperature
//     containerStackId: Cura.MachineManager.activeMachineId
//     key: "material_bed_temperature"
//     watchedProperties: ["value", "minimum_value", "maximum_value", "resolve"]
//     storeIndex: 0

//     property var resolve: Cura.MachineManager.activeStackId != Cura.MachineManager.activeMachineId ? properties.resolve : "None"
// }