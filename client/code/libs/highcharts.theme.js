Highcharts.theme = {
    //colors: ["#DDDF0D", "#7798BF", "#55BF3B", "#DF5353", "#aaeeee", "#ff0066", "#eeaaee",
//		"#55BF3B", "#DF5353", "#7798BF", "#aaeeee"],
    colors: ['#049CDB', '#46A546', '#FFC40D', '#C3325F', '#0064CD', '#9D261D', '#F89406', '#7A43B6',
            '#4572A7', '#AA4643', '#89A54E', '#80699B', '#3D96AE', '#DB843D', '#92A8CD', '#A47D7C', '#B5CA92'],
	chart: {
        backgroundColor: null,
		borderWidth: 0,
		borderRadius: 2,
		plotBackgroundColor: null,
		plotShadow: false,
		plotBorderWidth: 0,
        style: {
            color: '#AAA',
            font: 'bold 35px "Helvetica Neue", Helvetica, Arial, sans-serif',
        }
	},

    title: {
        style: {
            display: 'none',
        },
    },

	xAxis: {
		gridLineWidth: 0,
		lineColor: '#999',
		tickColor: '#999',
		labels: {
			style: {
				color: '#999',
				marginTop: "100px",
				font: 'bold 25px "Helvetica Neue", Helvetica, Arial, sans-serif',
			}
		},
		title: {
			style: {
				color: '#AAA',
				font: 'bold 35px "Helvetica Neue", Helvetica, Arial, sans-serif',
			}
		}
	},
	yAxis: {
		alternateGridColor: null,
		minorTickInterval: null,
		gridLineColor: 'rgba(255, 255, 255, .1)',
		lineWidth: 0,
		tickWidth: 0,
		labels: {
			style: {
				color: '#999',
				font: 'bold 25px "Helvetica Neue", Helvetica, Arial, sans-serif',
			}
		},
		title: {
			style: {
				color: '#AAA',
				font: 'bold 35px "Helvetica Neue", Helvetica, Arial, sans-serif',
			}
		}
	},
	legend: {
        enabled: false,
		itemStyle: {
			color: '#CCC'
		},
		itemHoverStyle: {
			color: '#FFF'
		},
		itemHiddenStyle: {
			color: '#333'
		}
	},
	labels: {
		style: {
			color: '#CCC',
            font: 'bold 30px "Helvetica Neue", Helvetica, Arial, sans-serif',
		}
	},
	tooltip: {
		backgroundColor: {
			linearGradient: [0, 0, 0, 50],
			stops: [
				[0, 'rgba(96, 96, 96, .8)'],
				[1, 'rgba(16, 16, 16, .8)']
			]
		},
		borderWidth: 0,
		style: {
			color: '#FFF'
		}
	},


	plotOptions: {
		line: {
			dataLabels: {
				color: '#AAA',
                style: {
                    font: 'bold 20px "Helvetica Neue", Helvetica, Arial, sans-serif',
                },
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
                color: '#AAA',
                style: {
                    font: 'bold 20px "Helvetica Neue", Helvetica, Arial, sans-serif',
                },
            },
        },
		candlestick: {
			lineColor: 'white'
		}
	},

	toolbar: {
		itemStyle: {
			color: '#CCC'
		}
	},

	navigation: {
		buttonOptions: {
			backgroundColor: {
				linearGradient: [0, 0, 0, 20],
				stops: [
					[0.4, '#606060'],
					[0.6, '#333333']
				]
			},
			borderColor: '#000000',
			symbolStroke: '#C0C0C0',
			hoverSymbolStroke: '#FFFFFF'
		}
	},

	exporting: {
		buttons: {
			exportButton: {
				symbolFill: '#55BE3B'
			},
			printButton: {
				symbolFill: '#7797BE'
			}
		}
	},

	// scroll charts
	rangeSelector: {
		buttonTheme: {
			fill: {
				linearGradient: [0, 0, 0, 20],
				stops: [
					[0.4, '#888'],
					[0.6, '#555']
				]
			},
			stroke: '#000000',
			style: {
				color: '#CCC',
				fontWeight: 'bold'
			},
			states: {
				hover: {
					fill: {
						linearGradient: [0, 0, 0, 20],
						stops: [
							[0.4, '#BBB'],
							[0.6, '#888']
						]
					},
					stroke: '#000000',
					style: {
						color: 'white'
					}
				},
				select: {
					fill: {
						linearGradient: [0, 0, 0, 20],
						stops: [
							[0.1, '#000'],
							[0.3, '#333']
						]
					},
					stroke: '#000000',
					style: {
						color: 'yellow'
					}
				}
			}
		},
		inputStyle: {
			backgroundColor: '#333',
			color: 'silver'
		},
		labelStyle: {
			color: 'silver'
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

	scrollbar: {
		barBackgroundColor: {
				linearGradient: [0, 0, 0, 20],
				stops: [
					[0.4, '#888'],
					[0.6, '#555']
				]
			},
		barBorderColor: '#CCC',
		buttonArrowColor: '#CCC',
		buttonBackgroundColor: {
				linearGradient: [0, 0, 0, 20],
				stops: [
					[0.4, '#888'],
					[0.6, '#555']
				]
			},
		buttonBorderColor: '#CCC',
		rifleColor: '#FFF',
		trackBackgroundColor: {
			linearGradient: [0, 0, 0, 10],
			stops: [
				[0, '#000'],
				[1, '#333']
			]
		},
		trackBorderColor: '#666'
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
