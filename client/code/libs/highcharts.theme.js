Highcharts.theme = {
    //colors: ["#DDDF0D", "#7798BF", "#55BF3B", "#DF5353", "#aaeeee", "#ff0066", "#eeaaee",
//		"#55BF3B", "#DF5353", "#7798BF", "#aaeeee"],
    colors: ['#049CDB', '#46A546', '#FFC40D', '#C3325F', '#0064CD', '#9D261D', '#F89406', '#7A43B6',
            '#4572A7', '#AA4643', '#89A54E', '#80699B', '#3D96AE', '#DB843D', '#92A8CD', '#A47D7C', '#B5CA92'],
	chart: {
        backgroundColor: null,
		borderWidth: 0,
		borderRadius: 2,
		height: 650,
		plotBackgroundColor: null,
		plotShadow: false,
		plotBorderWidth: 0,
		style: {
            fontSize: '45px'
        }
	},

	yAxis: {
		alternateGridColor: null,
		minorTickInterval: null,
		gridLineColor: 'rgba(255, 255, 255, .1)',
		lineWidth: 0,
		tickWidth: 0
	},
	legend: {
        enabled: true,
		itemStyle: {
		},
		itemHoverStyle: {
			color: '#FFF'
		},
		itemHiddenStyle: {
			color: '#333'
		}
	},
	tooltip: {
        enabled: false
	},
	plotOptions: {
		line: {
			dataLabels: {
				color: '#AAA'
			},
			marker: {
				lineColor: '#333'
			}
		},
		spline: {
			marker: {
				lineColor: '#333'
			}
		},
		scatter: {
			marker: {
				lineColor: '#333'
			}
		},
        pie: {
            dataLabels: {
                color: '#AAA'
            }
        }
	},

	toolbar: {
		itemStyle: {
			color: '#CCC'
		}
	},

	navigator: {
		handles: {
			backgroundColor: '#666',
			borderColor: '#AAA'
		},
		outlineColor: '#CCC',
		maskFill: 'rgba(16, 16, 16, 0.5)',
		series: {
			color: '#7798BF',
			lineColor: '#A6C7ED'
		}
	},


	// special colors for some of the demo examples
	legendBackgroundColor: 'rgba(48, 48, 48, 0.8)',
	legendBackgroundColorSolid: 'rgb(70, 70, 70)',
	dataLabelsColor: '#444',
	textColor: '#E0E0E0',
	maskColor: 'rgba(255,255,255,0.3)'
};

// Apply the theme
var highchartsOptions = Highcharts.setOptions(Highcharts.theme);
