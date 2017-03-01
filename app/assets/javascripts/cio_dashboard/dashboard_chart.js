$(function () {

$('#web1').highcharts({

    chart: {
        type: 'heatmap',
        marginTop: 3,
        marginBottom: 3,
        plotBorderWidth: 1
    },


    title: {
        text: ''
    },

    xAxis: {
        categories: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    },

    yAxis: {
        categories: ['Page Views'],
        title: null
    },

    colorAxis: {
        min: 6,
        minColor: '#FFFFFF',
        maxColor: Highcharts.getOptions().colors[0]
    },

     legend: {
        enabled: false
    },

    credits: {
        enabled: false
    },

    exporting: {
        enabled: false
    },

    tooltip: {
        formatter: function () {
            return '<b>' + this.series.xAxis.categories[this.point.x] + '</b> <br><b>' +
                this.point.value + '</b> thousand <br><b>' + this.series.yAxis.categories[this.point.y] + '</b>';
        }
    },

    series: [{
        name: 'Web Activity',
        borderWidth: 1,
        data: [[0, 0, 9.1], [1, 0, 6.9], [2, 0, 8], [3, 0, 8.1], [4, 0, 7.4], [5, 0, 8.1], [6, 0, 7.3]],
        dataLabels: {
            enabled: true,
            color: '#000000'
        }
    }]
    });

$('#web2').highcharts({

    chart: {
        type: 'heatmap',
        marginTop: 3,
        marginBottom: 3,
        plotBorderWidth: 1
    },


    title: {
        text: ''
    },

    xAxis: {
        categories: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    },

    yAxis: {
        categories: ['load Time'],
        title: null
    },

    colorAxis: {
        min: 1,
        minColor: '#FFFFFF',
        maxColor: Highcharts.getOptions().colors[0]
    },

     legend: {
        enabled: false
    },

    credits: {
        enabled: false
    },

    exporting: {
        enabled: false
    },

    tooltip: {
        formatter: function () {
            return '<b>' + this.series.xAxis.categories[this.point.x] + '</b> <br><b>' +
                this.point.value + '</b> seconds <br><b>' + this.series.yAxis.categories[this.point.y] + '</b>';
        }
    },

    series: [{
        name: 'Web Activity',
        borderWidth: 1,
        data: [[0, 0, 1.1], [1, 0, 1.9], [2, 0, 1], [3, 0, 1.1], [4, 0, 1.4], [5, 0, 1.1], [6, 0, 1.3]],
        dataLabels: {
            enabled: true,
            color: '#000000'
        }
    }]
    });
});
       