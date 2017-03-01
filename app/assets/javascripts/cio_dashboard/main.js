$(function () {
    $('#events1').highcharts({
        chart: {
            borderColor: '#000000',
            borderWidth: 0,
            type: 'column',
            height: 200
        },
        title: {
            text: ''
        },
        xAxis: {
            categories: [
                'One Big SHOP',
                'Financial Management',
                'Reporting',
                'B2B Gateway',
                'QHP Integration'

            ]
        },
        yAxis: [{
            min: 0,
            title: {
                text: 'Percent',
                margin: 40
            }
        }, {
            title: {
                text: ''
            },
            opposite: true
        }],
        legend: {
            shadow: false,
            itemDistance: 50
        },
        credits: {
            enabled: false
        },
        exporting: {
            enabled: false
        },
        tooltip: {
            shared: true
        },
        plotOptions: {
            column: {
                grouping: false,
                shadow: false,
                borderWidth: 0
            }
        },
        series: [{
            name: 'Target',
            color: 'rgba(165,170,217,1)',
            data: [60, 50, 60, 25, 25],
            pointPadding: 0.3,
            pointPlacement: -0.0
        }, {
            name: 'Completed',
            color: 'rgba(126,86,134,.9)',
            data: [65, 48, 38, 25, 25],
            pointPadding: 0.4,
            pointPlacement: -0.0
        }]
    });
});