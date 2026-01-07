# UI Definition using navbarPage - DATA TAB ONLY - CORRECTED


library(shiny)
library(shinythemes)
library(shinyjs)
library(shinyWidgets)
library(DT)
library(plotly)
library(shinycssloaders)
library(webshot2)
library(pagedown)







ui <- tagList( # Wrap the entire UI in tagList
  
  # Place useShinyjs() and tags$head() OUTSIDE navbarPage
  useShinyjs(),
  tags$head(
    # Link Google Font
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Montserrat:wght@400;700&display=swap"),
    tags$style(
      HTML(
        "
      /* Apply Montserrat font globally */
      body {
        font-family: 'Montserrat', sans-serif;
        background-color: #f8f9fa; /* Light background */
      }
      /* --- Other CSS rules remain the same --- */
      .navbar-default { background-color: #ffffff; border-color: #e7e7e7; }
      .navbar-default .navbar-brand { color: #333333; }
      .navbar-default .navbar-nav > .active > a,
      .navbar-default .navbar-nav > .active > a:hover,
      .navbar-default .navbar-nav > .active > a:focus { color: #ffffff; background-color: #e74c3c; }
      .navbar-default .navbar-nav > li > a:hover,
      .navbar-default .navbar-nav > li > a:focus { color: #ffffff; background-color: #c0392b; }
      .panel { border-radius: 3px; box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24); border: none; margin-bottom: 20px; }
      .panel-heading { font-weight: bold; border-bottom: 1px solid #f4f4f4; background-color: #f5f5f5 !important; color: #333; }
      .panel-primary > .panel-heading { background-color: #337ab7 !important; color: white; }
      .panel-success > .panel-heading { background-color: #00a65a !important; color: white; }
      .item-selector { background-color: white; padding: 15px; border-radius: 3px; border-left: 4px solid #00a65a; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24); }
      .help-tooltip { color: #666; margin-left: 8px; cursor: pointer; }
      .status-box { background-color: #fff; border-radius: 3px; padding: 15px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24); text-align: center; border-left: 4px solid #337ab7; }
      .status-box h4 { font-size: 24px; font-weight: bold; margin-top: 0; margin-bottom: 5px; }
      .status-box p { font-size: 14px; color: #666; margin-bottom: 0; }
      .status-box i { font-size: 30px; color: #ccc; position: absolute; top: 15px; right: 15px; opacity: 0.3; }
      .status-box-red { border-left-color: #e74c3c; }
      .status-box-green { border-left-color: #00a65a; }
      .status-box-blue { border-left-color: #3498db; }
      .status-box-yellow { border-left-color: #f39c12; }
      .status-box-purple { border-left-color: #8e44ad; }
      .status-box-orange { border-left-color: #e67e22; }
      .btn-success { background-color: #00a65a !important; border-color: #008d4c !important; color: white !important; }
      .btn-success:hover { background-color: #008d4c !important; border-color: #00733e !important; }
      .btn-info { background-color: #00c0ef !important; border-color: #00a7d0 !important; color: white !important; }
      .btn-info:hover { background-color: #00a7d0 !important; border-color: #008bb4 !important; }
      .btn-primary { background-color: #337ab7 !important; border-color: #2e6da4 !important; color: white !important; }
      .btn-primary:hover { background-color: #286090 !important; border-color: #204d74 !important; }
      .btn-warning { background-color: #f39c12 !important; border-color: #e08e0b !important; color: white !important; }
      .btn-warning:hover { background-color: #e08e0b !important; border-color: #c87f0a !important; }
      .js-plotly-plot .plotly, .js-plotly-plot .plotly-graph-div { width: 100% !important; }
      
      /* Data Input Section Alignment */
      .data-input-container {
        display: grid !important;
        grid-template-columns: repeat(3, 1fr);
        gap: 20px;
        align-items: stretch;
      }
      
      .data-input-column {
        display: flex !important;
        flex-direction: column;
        min-height: 300px;
      }
      
      .data-input-header {
        min-height: 60px;
        display: flex;
        align-items: flex-start;
      }
      
      .data-input-content {
        flex: 1;
        display: flex;
        flex-direction: column;
      }
      
      .data-input-text-area {
        height: 120px;
        display: flex;
        flex-direction: column;
        justify-content: flex-start;
        overflow: hidden;
        padding-bottom: 15px;
      }
      
      .data-input-button-area {
        height: 80px;
        display: flex;
        align-items: flex-start;
        justify-content: flex-start;
        margin: 0;
        padding-top: 10px;
      }
      
      .data-input-info {
        margin-top: auto;
      }
      
      @media (max-width: 768px) {
        .data-input-container {
          grid-template-columns: 1fr;
        }
      }
      "
      )
      
      
    ) # End tags$style
  ), # End tags$head
  
  # Now define the navbarPage
  navbarPage( 
    id = "main_nav",
    # Add Logo and Title
    title = div(
      tags$img(
        src = "logo.png",
        height = "30px",
        style = "margin-top: -5px; padding-right: 10px;"
      ),
      span("Lucent", style = "font-size: 20px; font-weight: bold;"),
      span(" - SEE Into the Future", style = "font-size: 12px;")
    ),
    windowTitle = "Lucent Forecasting",
    collapsible = TRUE,
    # theme = shinytheme("flatly"), # Optional
    
    # ============================
    # Tab Panel Definitions Start Here
    # ============================
    
    # ===== Data Tab =====
    tabPanel(
      title = "Data",
      icon = icon("database"),
      value = "data",
      
      fluidPage(
        # Use fluidPage inside tabPanel for layout control
        # App introduction
        fluidRow(
          column(
            12, div(
              class = "panel panel-success",
              div(class = "panel-heading", "Welcome to Lucent"),
              div(
                class = "panel-body",
                div(
                  style = "display: flex; flex-wrap: wrap; gap: 20px; align-items: center;",
                  div(
                    style = "flex: 2; min-width: 300px;",
                    h4("Advanced Time Series Forecasting Tool"),
                    p("Upload your time series data, analyze patterns, and generate accurate forecasts with various statistical methods."),
                    p("This tool supports:", style = "margin-bottom: 5px;"),
                    tags$ul(
                      tags$li("Multiple forecasting methods (ARIMA, Exponential Smoothing, Prophet)"),
                      tags$li("Data preprocessing (outlier detection, missing values, aggregation)"),
                      tags$li("Interactive visualization of results"),
                      tags$li("Model diagnostics and performance metrics"),
                      tags$li("Export of forecast results")
                    )
                  ),
                  div(
                    style = "flex: 1; min-width: 200px; text-align: center;",
                    icon("chart-line", style = "font-size: 100px; color: #00a65a; opacity: 0.2;")
                  )
                )
              ) # End panel-body
            ) # End panel
          )
        ),
        
        # Status indicators
        fluidRow(
          column(3, uiOutput("data_status_box")),
          column(3, uiOutput("items_count_box")),
          column(3, uiOutput("date_range_box")),
          column(3, uiOutput("forecast_status_box"))
        ),
        # Data upload section
        fluidRow(column(
          12, div(
            class = "panel panel-primary",
            div(class = "panel-heading", "Data Input"),
            div(
              class = "panel-body",
              div(
                class = "data-input-container",
                # Upload area
                div(
                  class = "data-input-column",
                  div(
                    class = "data-input-header",
                    h4("Upload Your Data")
                  ),
                  div(
                    class = "data-input-content",
                    div(
                      class = "data-input-text-area",
                      p("Upload Data File CSV or Excel file with your time series data, Your data must have headers. Use download template for guidance.")
                    ),
                    div(
                      class = "data-input-button-area",
                      fileInput(
                        "file",
                        NULL,
                        accept = c(".csv", ".xlsx"),
                        buttonLabel = "Browse...",
                        placeholder = "No file selected"
                      )
                    ),
                    div(
                      class = "alert alert-info data-input-info",
                      icon("info-circle"),
                      HTML("Required format: Data with <b>Date</b>, <b>Entity_ID</b>, <b>Entity_Name</b>, and <b>Volume</b> columns.")
                    )
                  )
                ),
                # Sample data area
                div(
                  class = "data-input-column",
                  div(
                    class = "data-input-header",
                    h4("Use Sample Data")
                  ),
                  div(
                    class = "data-input-content",
                    div(
                      class = "data-input-text-area",
                      p("Want to try the application right away? Load our sample dataset with multiple items and time series.")
                    ),
                    div(
                      class = "data-input-button-area",
                      actionButton("load_sample_data", "Load Sample Data", class = "btn-success", icon = icon("play"))
                    ),
                    div(
                      class = "alert alert-info data-input-info",
                      icon("info-circle"),
                      "Sample data includes 3 items with 6 months of daily sales data, trends, and seasonality patterns."
                    )
                  )
                ),
                # Template area
                div(
                  class = "data-input-column",
                  div(
                    class = "data-input-header",
                    h4("Download Template")
                  ),
                  div(
                    class = "data-input-content",
                    div(
                      class = "data-input-text-area",
                      p("Not sure about the format? Download our template for guidance.")
                    ),
                    div(
                      class = "data-input-button-area",
                      downloadButton("download_Tem", "Download Template", class = "btn-primary")
                    ),
                    div(
                      class = "alert alert-success data-input-info",
                      icon("lightbulb"),
                      "The template includes sample data you can use to test the application."
                    )
                  )
                )
              ) # End container
            ) # End panel-body
          ) # End panel
        ) # End column),
        # End fluidRow
        ),
        # Data preview section
        fluidRow(
          column(12, div(
            class = "panel panel-primary",
            div(class = "panel-heading", "Data Preview"),
            div(class = "panel-body", withSpinner(
              DTOutput("data_preview"),
              type = 8,
              color = "#00a65a"
            ))
          )),
          column(4, "") # Empty right column for spacing
        ),
        
        # Data summary section
        fluidRow(column(
          12,
          tabsetPanel(
            id = "data_summary_tabs",
            type = "tabs",
            tabPanel(
              "Summary Statistics (Current Entity)",
              withSpinner(verbatimTextOutput("data_summary"), type = 8, color = "#00a65a")
            ),
            tabPanel(
              "Data Structure",
              withSpinner(verbatimTextOutput("data_structure"), type = 8, color = "#00a65a")
            ),
            tabPanel(
              "Missing Values",
              withSpinner(plotOutput("missing_values_plot"), type = 8, color = "#00a65a")
            )
          ) # End tabsetPanel
        ) # End column) # End fluidRow
        )
      ) # End fluidPage
    ) ,# End Data tabPanel
    ################################
    # ===== Preprocessing Tab =====
    ################################
    
    # ===== Preprocessing Tab =====
    tabPanel(
      title = "Preprocessing",
      icon = icon("filter"),
      value = "preprocessing",
      
      fluidPage(fluidRow(# Item selection box
        column(
          12, div(
            class = "panel panel-primary",
            div(class = "panel-heading", "Select Entity"),
            div(
              class = "panel-body",
              div(
                style = "display: flex; flex-wrap: wrap; align-items: center; gap: 15px;",
                div(
                  style = "flex: 3; min-width: 250px;",
                  selectizeInput(
                    "selectentity",
                    "Entity to Analyze:",
                    choices = NULL, # Populated by server
                    options = list(
                      placeholder = "Select an entity to analyze",
                      onInitialize = I('function() { this.setValue(""); }')
                    )
                  )
                ),
                div(
                  style = "flex: 1; min-width: 150px; text-align: right;",
                  checkboxInput("show_all_items", "Show combined view for all items", FALSE)
                )
              )
            ) # end panel-body
          ) # end panel
        ) # End column), # End fluidRow
      ),
      
      # Data statistics for current item (moved below item selection)
      div(
        class = "panel panel-primary",
        div(class = "panel-heading", "Statistics (Current Entity)"),
        div(
          class = "panel-body",
          div(
            class = "row", # Add a row container for stats boxes
            div(class = "col-md-2 col-sm-4", uiOutput("stats_n_obs")),
            div(class = "col-md-2 col-sm-4", uiOutput("stats_mean")),
            div(class = "col-md-2 col-sm-4", uiOutput("stats_stdev")),
            div(class = "col-md-2 col-sm-4", uiOutput("stats_missing")),
            div(class = "col-md-2 col-sm-4", uiOutput("stats_outliers"))
            # Add more cols if needed, adjust col-md/col-sm classes for layout
          )
        ) # end panel-body
      ), # end panel
      
      fluidRow(
        # Left column for Status and Actions
        column(
          width = 3,
          # Preprocessing status panel
          div(
            class = "panel panel-success",
            div(class = "panel-heading", "Current Data Status"),
            div(
              class = "panel-body",
              uiOutput("data_status_indicators"),
              hr(),
              h4("Applied Preprocessing:"),
              verbatimTextOutput("preprocessing_summary"),
              hr(),
              # Action buttons
              div(
                style = "display: flex; flex-direction: column; gap: 10px;",
                actionButton(
                  "apply_preprocessing",
                  "Apply All Changes",
                  icon = icon("check-circle"),
                  class = "btn-success btn-block"
                ),
                actionButton(
                  "reset_preprocessing",
                  "Reset to Original",
                  icon = icon("undo"),
                  class = "btn-warning btn-block"
                ),
                downloadButton("download_preprocessed", "Download Processed Data", class = "btn-info btn-block")
              )
            ) # end panel-body
          ), # end panel
        ), # End column(width=3)
        
        # Right column for Visualization and Options
        column(
          width = 9,
          # Data visualization panel
          div(
            class = "panel panel-primary",
            div(class = "panel-heading", "Time Series Visualization"),
            div(
              class = "panel-body",
              div(
                style = "display: flex; justify-content: flex-end; margin-bottom: 10px;",
                div(
                  style = "display: flex; align-items: center; gap: 10px;",
                  selectInput(
                    "plot_type",
                    "Plot Type:",
                    choices = c("Line", "Bar", "Point", "Area"),
                    selected = "Line",
                    width = "120px"
                  ),
                  checkboxInput("show_outliers", "Highlight Outliers", TRUE)
                )
              ),
              withSpinner(
                plotlyOutput("preprocessing_plot", height = "300px"),
                type = 8,
                color = "#00a65a"
              )
            ) # End panel-body
          ), # End panel
          
          # Tabbed preprocessing options
          tabsetPanel(
            id = "preprocessing_tabs",
            type = "tabs",
            # Tab 1: Data Cleaning
            tabPanel(
              "Data Cleaning",
              fluidRow(
                column(
                  width = 6,
                  h4("Handle Missing Values"),
                  selectInput(
                    "missing_treatment",
                    "Method:",
                    choices = c(
                      "Linear Interpolation" = "linear",
                      "Forward Fill" = "ffill",
                      "Backward Fill" = "bfill",
                      "Mean Fill" = "mean",
                      "Median Fill" = "median",
                      "Remove Rows" = "remove"
                    ),
                    selected = "linear"
                  ),
                  actionButton("apply_missing", "Apply", class = "btn-primary")
                ),
                column(
                  width = 6,
                  h4("Handle Duplicates"),
                  selectInput(
                    "duplicate_handling",
                    "Method:",
                    choices = c(
                      "Keep All" = "keep",
                      "Keep First" = "first",
                      "Keep Last" = "last",
                      "Aggregate Sum" = "sum",
                      "Aggregate Mean" = "mean"
                    ),
                    selected = "keep"
                  ),
                  actionButton("apply_duplicates", "Apply", class = "btn-primary")
                )
              ),
              hr(),
              fluidRow(column(
                width = 12,
                h4("Handle Outliers"),
                fluidRow(
                  column(
                    width = 4,
                    selectInput(
                      "outlier_method",
                      "Detection Method:",
                      choices = c(
                        "IQR Method" = "iqr",
                        "Z-Score" = "zscore",
                        "GESD Test" = "gesd" # Note: GESD logic wasn't in original server snippet
                      ),
                      selected = "iqr"
                    )
                  ),
                  column(
                    width = 4,
                    sliderInput(
                      "outlier_threshold",
                      "Threshold:",
                      min = 1.5,
                      max = 5,
                      value = 3,
                      step = 0.1
                    )
                  ),
                  column(
                    width = 4,
                    selectInput(
                      "outlier_action",
                      "Action:",
                      choices = c(
                        "Keep Outliers" = "keep",
                        "Remove Outliers" = "remove",
                        "Replace with Mean" = "mean",
                        "Replace with Median" = "median",
                        "Winsorize" = "winsorize"
                      ),
                      selected = "keep"
                    )
                  )
                ),
                actionButton("apply_outliers", "Apply", class = "btn-primary")
              ),
              
              hr(),
              fluidRow(column(
                width = 12,
                h4("Custom Value Replacement"),
                fluidRow(
                  column(
                    width = 2,
                    selectInput(
                      "value_condition",
                      "Condition:",
                      choices = c(
                        "Less than" = "less_than",
                        "Greater than" = "greater_than",
                        "Between" = "between",
                        "Equal to" = "equal_to"
                      ),
                      selected = "less_than"
                    )
                  ),
                  column(
                    width = 2,
                    numericInput(
                      "value_threshold1",
                      "Value 1:",
                      value = 0,
                      step = 0.01
                    )
                  ),
                  column(
                    width = 2,
                    conditionalPanel(
                      condition = "input.value_condition === 'between'",
                      numericInput(
                        "value_threshold2",
                        "Value 2:",
                        value = 10,
                        step = 0.01
                      )
                    )
                  ),
                  # With this enhanced version:
                  column(
                    width = 4,
                    selectInput(
                      "replacement_method",
                      "Replace with:",
                      choices = c(
                        "Mean of Same Weekday" = "weekday_mean",
                        "Median of Same Weekday" = "weekday_median", 
                        "Specific Value" = "specific_value"
                      ),
                      selected = "specific_value"
                    )
                  ),
                  column(
                    width = 2,
                    conditionalPanel(
                      condition = "input.replacement_method === 'specific_value'",
                      numericInput(
                        "replacement_value",
                        "Value:",
                        value = 0,
                        step = 0.01
                      )
                    )
                  )
                ),
                fluidRow(
                  column(
                    width = 8,
                    div(
                      id = "value_replacement_preview",
                      class = "alert alert-info",
                      style = "margin-top: 10px; font-size: 90%;",
                      icon("info-circle"),
                      span("Select condition and values to see preview of affected records.")
                    )
                  ),
                  column(
                    width = 4,
                    div(style = "margin-top: 10px;",
                        actionButton("apply_value_replacement", "Apply Replacement", class = "btn-primary")
                    )
                  )
                )
              ))
              
              
              
              
              
              
              )
              
              
              
              
              
              
            ), 
            
            
            
            # End Data Cleaning tabPanel
            
            # Tab 2: Time Aggregation
            tabPanel(
              "Time Aggregation",
              fluidRow(
                column(
                  width = 6,
                  selectInput(
                    "data_aggregation",
                    "Aggregation Level:",
                    choices = c(
                      "None" = "none",
                      "Daily to Weekly" = "weekly",
                      "Daily to Monthly" = "monthly",
                      "Weekly to Monthly" = "weekly_to_monthly",
                      "Custom" = "custom"
                    ),
                    selected = "none"
                  ),
                  conditionalPanel(
                    condition = "input.data_aggregation === 'custom'",
                    numericInput(
                      "agg_period",
                      "Custom Period (Days):",
                      7,
                      min = 1,
                      max = 365
                    )
                  )
                ),
                column(
                  width = 6,
                  selectInput(
                    "agg_method",
                    "Aggregation Method:",
                    choices = c(
                      "Sum" = "sum",
                      "Mean" = "mean",
                      "Median" = "median",
                      "Maximum" = "max",
                      "Minimum" = "min"
                    ),
                    selected = "sum"
                  )
                )
              ),
              withSpinner(
                plotlyOutput("aggregation_preview", height = "250px"), # Needs server logic
                type = 8,
                color = "#00a65a"
              ),
              div(
                style = "margin-top: 15px; text-align: center;",
                actionButton("apply_aggregation", "Apply Aggregation", class = "btn-primary") # Needs server logic
              )
            ), # End Aggregation tabPanel
            
            # Tab 3: Transformation & Seasonality - COMMENTED OUT
            # tabPanel(
            #   "Transformation & Seasonality",
            #   fluidRow(
            #     column(
            #       width = 6,
            #       h4("Data Transformation"),
            #       selectInput(
            #         "transform_method",
            #         "Transformation Method:",
            #         choices = c(
            #           "None" = "none",
            #           "Log" = "log",
            #           "Square Root" = "sqrt",
            #           "Box-Cox" = "boxcox",
            #           "Standardize (Z-score)" = "zscore",
            #           "Min-Max Scaling" = "minmax"
            #         ),
            #         selected = "none"
            #       ),
            #       conditionalPanel(
            #         condition = "input.transform_method === 'boxcox'",
            #         sliderInput("lambda", "Lambda Value:", -2, 2, 0, step = 0.1)
            #       ),
            #       actionButton("apply_transform", "Apply Transformation", class = "btn-primary")
            #     ),
            #     column(
            #       width = 6,
            #       h4("Seasonal Adjustment"),
            #       selectInput(
            #         "seasonality_method",
            #         "Seasonal Adjustment Method:",
            #         choices = c(
            #           "None" = "none",
            #           "Seasonal Decomposition" = "decompose",
            #           "STL Decomposition" = "stl",
            #           "Moving Average" = "ma"
            #         ),
            #         selected = "none"
            #       ),
            #       checkboxInput("adjust_seasonality", "Remove Seasonality", FALSE),
            #       conditionalPanel(
            #         condition = "input.adjust_seasonality === true",
            #         radioButtons(
            #           "seasonal_type",
            #           "Seasonal Type:",
            #           choices = c("Additive", "Multiplicative"),
            #           selected = "Additive"
            #         )
            #       ),
            #       actionButton("apply_seasonal", "Apply Seasonal Adjustment", class = "btn-primary")
            #     )
            #   ), # End fluidRow for transform/seasonal inputs
            #   # Preview plot for this tab
            #   withSpinner(
            #     plotlyOutput("transformation_preview", height = "250px"),
            #     type = 8,
            #     color = "#00a65a"
            #   )
            # ) # End Transformation tabPanel
          ) # End tabsetPanel
        ) # End column(width=9)
      ) # End fluidRow
      ) # End fluidPage
    ), # End Preprocessing tabPanel
    
        # ============================
        # Tab Panel Definitions Start Here
        # ============================
        
    # ===== Forecast Tab =====
    tabPanel(
      title = "Forecast",
      icon = icon("chart-line"),
      value = "forecast",
      
      fluidPage(
        fluidRow(# Selected item indicator
          column(
            12, div(
              class = "panel panel-primary",
              div(class = "panel-heading", "Select Entity for Forecasting"),
              div(
                class = "panel-body item-selector", # Kept item-selector styling
                div(
                  style = "display: flex; flex-wrap: wrap; align-items: center; gap: 15px;",
                  div(
                    style = "flex: 3; min-width: 250px;",
                    selectizeInput(
                      "forecast_entity",
                      "Entity to Forecast:",
                      choices = NULL, # Populated by server
                      options = list(
                        placeholder = "Select an entity to forecast",
                        onInitialize = I('function() { this.setValue(""); }')
                      )
                    )
                  ),
                  div(
                    style = "flex: 1; min-width: 150px; text-align: right;",
                    # Changed from forecast_all_items to batch_forecast for consistency with later UI
                    checkboxInput("batch_forecast", "Forecast all items", FALSE)
                  )
                )
              ) # end panel-body
            ) # end panel
          ) # end col), # End fluidRow
        ), # End fluidRow for item selection
        
        
        fluidRow(
          # Left Column: Forecast Settings & Run
          column(
            width = 4,
            # Basic forecast settings panel
            div(
              class = "panel panel-primary",
              div(class = "panel-heading", "Forecast Settings"),
              div(
                class = "panel-body",
                numericInput(
                  "h_value",
                  "Forecast Horizon (periods):",
                  value = 7,
                  min = 1,
                  max = 365
                ),
                selectInput(
                  "frequency",
                  "Data Frequency:",
                  choices = c(
                    "Daily" = 1,
                    "Weekly" = 7,
                    "Monthly" = 30,
                    "Quarterly" = 91,
                    "Yearly" = 365
                  ),
                  selected = 7 # Default to Weekly
                ),
                checkboxInput("auto_frequency", "Auto-detect frequency", TRUE),
                hr(),
                checkboxInput("use_prediction_intervals", "Show prediction intervals", TRUE),
                conditionalPanel(
                  condition = "input.use_prediction_intervals == true", # JS condition
                  sliderInput(
                    "prediction_interval",
                    "Confidence Level (%):", # Added % sign
                    min = 50,
                    max = 99,
                    value = 80,
                    step = 5
                  )
                ),
                hr(),
                h4("Advanced Settings"),
                checkboxInput("enable_cv", "Enable Cross-Validation (on Results Tab)", FALSE), # Clarified where CV results appear
                conditionalPanel(
                  condition = "input.enable_cv == true",
                  numericInput(
                    "cv_folds", # ID was cv_folds in original, keep for consistency
                    "Number of Folds:",
                    value = 3, # Default changed from 5
                    min = 2,
                    max = 10
                  ),
                  selectInput(
                    "cv_method", # ID was cv_method in original
                    "CV Method:",
                    choices = c("Rolling Window" = "rolling", "Expanding Window" = "expanding"),
                    selected = "rolling"
                  )
                ),
                checkboxGroupInput(
                  "metrics", # ID was metrics in original
                  "Performance Metrics to Calculate:",
                  choices = c("MAE", "RMSE", "MAPE"),
                  selected = c("MAE", "RMSE", "MAPE")
                )
              ) # end panel-body
            ), # end forecast settings panel
            
            # Run forecast panel
            div(
              class = "panel panel-success",
              div(class = "panel-heading", "Run Forecast"),
              div(
                class = "panel-body",
                conditionalPanel(
                  condition = "input.batch_forecast == true", # Use the checkbox from item selection
                  sliderInput(
                    "parallel_cores",
                    "Parallel Processing Cores:",
                    min = 1,
                    max = 4, # Simplified to avoid parallel::detectCores() dependency in UI
                    value = 2, # Default to 2 cores
                    step = 1
                  )
                ),
                div(
                  style = "text-align: center; margin-top: 20px;",
                  actionButton(
                    "go",
                    "Run Forecast",
                    icon = icon("play"),
                    class = "btn-success btn-lg",
                    style = "width: 100%; padding: 10px;"
                  )
                ),
                div(
                  style = "margin-top: 15px;",
                  div(
                    class = "alert alert-info",
                    icon("info-circle"),
                    "Forecast generation may take time depending on data size and method."
                  )
                )
              ) # end panel-body
            ) # end run forecast panel
            
          ), # End column(width=4)
          
          
          # Right Column: Method Selection & Preview
          column(
            width = 8,
            # Forecasting method selection panel
            div(
              class = "panel panel-primary",
              div(class = "panel-heading", "Forecasting Method"),
              div(
                class = "panel-body",
                # Method selection cards (Radio buttons)
                fluidRow(column(
                  width = 12,
                  div( # Container for method cards
                    style = "display: flex; flex-wrap: wrap; gap: 10px; justify-content: space-between;",
                    
                    # ARIMA method card
                    div( style = "flex: 1; min-width: 250px; border: 1px solid #ddd; border-radius: 5px; padding: 15px; background-color: #f9f9f9;",
                         div( style = "display: flex; align-items: center; margin-bottom: 10px;",
                              radioButtons( "method", NULL, # Use single ID for radio group
                                            choiceNames = list(HTML("<strong>ARIMA</strong>")),
                                            choiceValues = list("ARIMA"), inline = TRUE, selected = "ARIMA" # Default selected
                              ),
                              div( style = "margin-left: auto;", icon("info-circle", class = "help-tooltip", `data-toggle`="tooltip", title="Auto-Regressive Integrated Moving Average") )
                         ),
                         p(style = "font-size: 90%; color: #555;", "Best for: Stationary data with trend/seasonality.")
                    ), # End ARIMA card
                    
                    # ETS method card
                    div( style = "flex: 1; min-width: 250px; border: 1px solid #ddd; border-radius: 5px; padding: 15px; background-color: #f9f9f9;",
                         div( style = "display: flex; align-items: center; margin-bottom: 10px;",
                              radioButtons( "method", NULL, # Same ID 'method'
                                            choiceNames = list(HTML("<strong>Exponential Smoothing</strong>")),
                                            choiceValues = list("Exponential Smoothing"), inline = TRUE
                              ),
                              div( style = "margin-left: auto;", icon("info-circle", class = "help-tooltip", `data-toggle`="tooltip", title="ETS models with error, trend, seasonality") )
                         ),
                         p(style = "font-size: 90%; color: #555;", "Best for: Data with clear trend/seasonality.")
                    ), # End ETS card
                    
                    # Prophet method card
                    div( style = "flex: 1; min-width: 250px; border: 1px solid #ddd; border-radius: 5px; padding: 15px; background-color: #f9f9f9;",
                         div( style = "display: flex; align-items: center; margin-bottom: 10px;",
                              radioButtons( "method", NULL, # Same ID 'method'
                                            choiceNames = list(HTML("<strong>Prophet</strong>")),
                                            choiceValues = list("Prophet"), inline = TRUE
                              ),
                              div( style = "margin-left: auto;", icon("info-circle", class = "help-tooltip", `data-toggle`="tooltip", title="Facebook's algorithm for business time series") )
                         ),
                         p(style = "font-size: 90%; color: #555;", "Best for: Business TS with multiple seasonality, holidays.")
                    ) # End Prophet card
                  ) # End flex container for cards
                ) # End column
                ), # End fluidRow for method cards
                
                hr(),
                
                # --- Method-specific settings ---
                # Conditional Panel for ARIMA settings
                conditionalPanel(
                  condition = "input.method === 'ARIMA'",
                  h4("ARIMA Settings"),
                  fluidRow(
                    column(6, 
                           checkboxInput("auto_arima", "Use auto.arima (recommended)", TRUE)
                    ),
                    column(6,
                           conditionalPanel(
                             condition = "!input.auto_arima",
                             div(style="display: flex; gap: 10px;",
                                 numericInput("p_value", "p:", 1, 0, 5, width="80px"),
                                 numericInput("d_value", "d:", 1, 0, 2, width="80px"),
                                 numericInput("q_value", "q:", 1, 0, 5, width="80px")
                             ),
                             helpText("p: AR order, d: differencing, q: MA order")
                           )
                    )
                  ),
                  fluidRow(
                    column(12,
                           conditionalPanel(
                             condition = "!input.auto_arima",
                             checkboxInput("seasonal_arima", "Include seasonal component", TRUE),
                             conditionalPanel(
                               condition = "input.seasonal_arima == true",
                               div(style="display: flex; gap: 10px;",
                                   numericInput("P_value", "P:", 1, 0, 2, width="80px"),
                                   numericInput("D_value", "D:", 0, 0, 1, width="80px"),
                                   numericInput("Q_value", "Q:", 1, 0, 2, width="80px"),
                                   numericInput("S_value", "Period:", 12, 1, 52, width="80px")
                               ),
                               helpText("P: Seasonal AR, D: Seasonal differencing, Q: Seasonal MA, Period: Seasonal cycle length")
                             )
                           )
                    )
                  ),
                  div(class = "alert alert-info",
                      style = "margin-top: 10px; font-size: 90%;",
                      icon("info-circle"),
                      HTML("Auto ARIMA will automatically select optimal model parameters.")
                  )
                ), # End ARIMA conditionalPanel
                
                # Conditional Panel for ETS settings
                conditionalPanel(
                  condition = "input.method === 'Exponential Smoothing'",
                  h4("Exponential Smoothing Settings"),
                  fluidRow(
                    column(6, checkboxInput("auto_ets", "Use automatic ETS (recommended)", TRUE)),
                    column(6,
                           conditionalPanel(
                             condition = "!input.auto_ets",
                             selectInput("ets_model", "ETS Model:",
                                         choices = c(
                                           "Simple (ANN)" = "ANN", "Holt (AAN)" = "AAN",
                                           "Additive HW (AAA)" = "AAA", "Multiplicative HW (MAM)" = "MAM",
                                           "Damped Additive HW (AAA, damped)" = "ZAA", # Example damped
                                           "Damped Multiplicative HW (MAM, damped)" = "ZMA" # Example damped
                                         ), selected = "ANN"
                             )
                           )
                    )
                  ), # end row for auto/model select
                  # Sliders appear only if model isn't auto_ets
                  conditionalPanel(
                    condition = "!input.auto_ets",
                    # You might want to disable/enable alpha/beta/gamma sliders based on selected ets_model
                    # For simplicity, showing all for now.
                    sliderInput("alpha", "Alpha (level):", 0.01, 0.99, 0.2, step=0.01),
                    sliderInput("beta",  "Beta (trend):", 0.01, 0.99, 0.1, step=0.01),
                    sliderInput("gamma", "Gamma (seasonal):", 0.01, 0.99, 0.1, step=0.01)
                  )
                ), # End ETS conditionalPanel
                
                # Conditional Panel for Prophet settings
                # Conditional Panel for Prophet settings
                # Conditional Panel for Prophet settings
                conditionalPanel(
                  condition = "input.method === 'Prophet'",
                  # Using prophet-settings-container class (from CSS) via fluidRow/column
                  fluidRow(class="prophet-settings-container",
                           column(width=12, h4("Prophet Settings")) # Title inside container
                  ),
                  
                  # NEW: Auto-optimization controls
                  fluidRow(class="prophet-settings-container",
                           column(12,
                                  div(style = "background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 4px; padding: 15px; margin-bottom: 15px;",
                                      div(style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px;",
                                          div(
                                            checkboxInput("auto_optimize_prophet", 
                                                          "Auto-optimize parameters based on data characteristics", 
                                                          value = TRUE),
                                            style = "margin: 0;"
                                          ),
                                          div(
                                            actionButton("refresh_prophet_params", 
                                                         "Refresh", 
                                                         icon = icon("sync-alt"), 
                                                         class = "btn-sm btn-outline-primary"),
                                            style = "margin-left: 10px;"
                                          )
                                      ),
                                      # Info panel for showing optimization results
                                      conditionalPanel(
                                        condition = "input.auto_optimize_prophet == true",
                                        div(id = "prophet_optimization_info",
                                            style = "background-color: white; border-radius: 3px; padding: 10px; font-size: 90%; margin-top: 10px;",
                                            icon("info-circle", style = "color: #17a2b8;"),
                                            span("Parameters will be automatically calculated based on the selected item's data characteristics.", 
                                                 style = "margin-left: 5px; color: #495057;")
                                        )
                                      )
                                  )
                           )
                  ),
                  
                  # Regressor Selection (conditionally rendered)
                  fluidRow(class="prophet-settings-container",
                           column(12, uiOutput("regressor_enhancement_panel"))
                  ),
                  
                  # Enhanced Prophet parameter controls with better help text control
                  fluidRow(class="prophet-settings-container",
                           column(6, # Left column for Prophet settings
                                  div(
                                    sliderInput("changepoint_prior", "Changepoint Prior Scale:", 
                                                min = 0.001, max = 0.5, value = 0.05, step = 0.01),
                                    # Help text with ID for dynamic updates
                                    div(id = "changepoint_help",
                                        style = "font-size: 85%; color: #6c757d; margin-top: -10px;",
                                        "Controls trend flexibility. Higher values = more flexible trends."
                                    )
                                  ),
                                  div(style = "margin-top: 15px;",
                                      checkboxInput("yearly_seasonality", "Yearly Seasonality", TRUE),
                                      checkboxInput("weekly_seasonality", "Weekly Seasonality", TRUE)
                                  )
                           ),
                           column(6, # Right column for Prophet settings
                                  div(
                                    sliderInput("seasonality_prior", "Seasonality Prior Scale:", 
                                                min = 0.01, max = 10, value = 0.5, step = 0.1),
                                    # Help text with ID for dynamic updates
                                    div(id = "seasonality_help",
                                        style = "font-size: 85%; color: #6c757d; margin-top: -10px;",
                                        "Controls seasonal pattern flexibility. Higher values = more flexible seasonality."
                                    )
                                  ),
                                  div(style = "margin-top: 15px;",
                                      checkboxInput("daily_seasonality", "Daily Seasonality", FALSE)
                                  )
                           )
                  ) # End Prophet settings row
                ) # End Prophet conditionalPanel
                
              ) # End panel-body for method selection
            ), # End panel for forecasting method
            
            
            # Forecast preview panel
            div(
              class = "panel panel-primary",
              div(class = "panel-heading", "Forecast Preview"),
              div(
                class = "panel-body",
                withSpinner(
                  plotlyOutput("forecast_preview", height = "300px"),
                  type = 8,
                  color = "#00a65a"
                ),
                div(
                  style = "margin-top: 15px; text-align: right;",
                  actionButton(
                    "update_preview",
                    "Update Preview",
                    icon = icon("sync"),
                    class = "btn-info"
                  )
                )
              ) # end panel-body
            ) # end forecast preview panel
            
          ) # End column(width=8)
          
        ) # End main fluidRow
        
      ) # End fluidPage for Forecast Tab
    ) # End Forecast tabPanel
    
    
    
            ,
    # ============================
    # Tab Panel Definitions Start Here
    # ============================
    
    # ===== Results Tab =====
    tabPanel(
      title = "Results",
      icon = icon("chart-bar"),
      value = "results",
      fluidPage(
        fluidRow(# Item selection for results
          column(12,
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Select Entity to View Results"),
                     div(class = "panel-body item-selector",
                         div(style = "display: flex; flex-wrap: wrap; align-items: center; gap: 15px;",
                             div(style = "flex: 3; min-width: 250px;",
                                 selectizeInput(
                                   "results_entity",
                                   "Entity:",
                                   choices = NULL, # Populated by server after forecast runs
                                   options = list(
                                     placeholder = "Select entity to view results",
                                     onInitialize = I('function() { this.setValue(""); }')
                                   )
                                 )
                             ),
                             div(style = "flex: 1; min-width: 150px; text-align: right;",
                                 # Download buttons for single item and all items
                                 div(style = "display: flex; flex-direction: column; gap: 8px; align-items: flex-end;",
                                     downloadButton("download", "Download Current Entity", class = "btn-info", style = "white-space: nowrap; min-width: 150px;"),
                                     downloadButton("download_all_entities", "Download All Entities", class = "btn-success", style = "white-space: nowrap; min-width: 150px;")
                                 )
                             )
                         )
                     ) # end panel-body
                 ) # end panel
          ) # end col
        ), # End fluidRow for item selection
        
        # Performance metrics (using uiOutput for dynamic rendering)
        fluidRow(
          column(4, uiOutput("mae_box")),
          column(4, uiOutput("rmse_box")),
          column(4, uiOutput("mape_box"))
        ), # End fluidRow for metrics
        
        fluidRow(
          # Left Column: Plot and Data Table/Stats
          column(width = 8,
                 # Forecast plot panel
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Forecast Results"),
                     div(class = "panel-body",
                         div(style = "display: flex; justify-content: flex-end; margin-bottom: 10px;",
                             div(style = "display: flex; align-items: center; gap: 10px;",
                                 selectInput(
                                   "results_plot_type", "Plot Type:",
                                   choices = c("Line", "Line with Points", "Area"),
                                   selected = "Line", width = "150px"
                                 ),
                                 checkboxInput("show_intervals", "Show Prediction Intervals", TRUE)
                             )
                         ),
                         withSpinner(plotlyOutput("results_plot", height = "350px"), type = 8, color = "#00a65a")
                     ) # End panel-body
                 ), # End plot panel
                 
                 # Tabbed view for details
                 tabsetPanel(id = "results_tabs", type = "tabs",
                             tabPanel("Data Table",
                                      div(style = "display: flex; justify-content: flex-end; margin-bottom: 10px;",
                                          div(style = "display: flex; align-items: center; gap: 10px;",
                                              selectInput(
                                                "table_view", "View:",
                                                choices = c("Forecast Only", "Historical + Forecast", "Full Data"),
                                                selected = "Forecast Only", width = "200px"
                                              )
                                          )
                                      ),
                                      withSpinner(DTOutput("results_table"), type = 8, color = "#00a65a")
                             ),
                             tabPanel("Forecast Statistics",
                                      # Needs careful definition of what stats to show
                                      withSpinner(verbatimTextOutput("forecast_stats"), type = 8, color = "#00a65a")
                             )
                 ) # End tabsetPanel
          ), # End column(width=8)
          
          # Right Column: Model Summary and Actions
          column(width = 4,
                 # Model summary panel
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Model Summary"),
                     div(class = "panel-body",
                         div(id = "model_summary_container", # Optional ID for styling
                             withSpinner(verbatimTextOutput("model_summary"), type = 8, color = "#00a65a")
                         ),
                         hr(),
                         div(class = "alert alert-info", icon("info-circle"), "Key parameters of the fitted model.")
                     ) # End panel-body
                 ), # End model summary panel
                 
                 # Cross-validation results panel (conditionally shown)
                 # ConditionalPanel depends on an *input* value.
                 # To show based on whether CV ran, we might need a reactive flag or check rv$comparison_metrics
                 # For simplicity, let's use the input$enable_cv from Forecast tab (assuming it persists)
                 conditionalPanel(condition = "input.enable_cv == true", # Check if CV was enabled on Forecast tab
                                  div(class = "panel panel-primary",
                                      div(class = "panel-heading", "Cross-Validation Results"),
                                      div(class = "panel-body",
                                          # Display CV metrics table (potentially from rv$comparison_metrics)
                                          withSpinner(DTOutput("cv_results"), type = 8, color="#00a65a"),
                                          # Display CV plot (e.g., boxplot of errors per fold/model)
                                          div(style="margin-top: 15px;", withSpinner(plotlyOutput("cv_plot", height = "200px"),type=8, color="#00a65a"))
                                      ) # End panel-body
                                  ) # End CV panel
                 ), # End conditionalPanel
                 
                 # Additional actions panel
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Actions"),
                     div(class = "panel-body",
                         div(style = "display: flex; flex-direction: column; gap: 10px;",
                             actionButton("export_report", "Export Full Report (Text)", icon = icon("file-alt"), class = "btn-primary btn-block"), # Needs handler
                             actionButton("rerun_forecast", "Adjust & Re-run Forecast", icon = icon("sync"), class = "btn-warning btn-block"),
                             actionButton("compare_models", "Compare Models (Diagnostics)", icon = icon("balance-scale"), class = "btn-info btn-block") # Clarified target tab
                         ),
                         hr(),
                         # Download format selection moved inside panel, linked to downloadButton above
                         selectInput("export_format", "Download Format:",
                                     choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv", "R Data (.rds)" = "rds"),
                                     selected = "xlsx"
                         )
                     ) # End panel-body
                 ) # End actions panel
          ) # End column(width=4)
        ) # End main fluidRow
      ) # End fluidPage
    ) # End Results tabPanel

    ,
    # ===== Diagnostics Tab =====
    tabPanel(
      title = "Diagnostics",
      icon = icon("stethoscope"),
      value = "diagnostics",
      
      fluidPage(
        fluidRow(# Item selection for diagnostics
          column(12,
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Select Entity for Diagnostics"),
                     div(class = "panel-body item-selector",
                         div(style = "display: flex; flex-wrap: wrap; align-items: center; gap: 15px;",
                             div(style = "flex: 3; min-width: 250px;",
                                 selectizeInput("diagnostics_entity", "Item:", 
                                                choices = NULL, 
                                                options = list(
                                                  placeholder = "Select an entity to analyze",
                                                  onInitialize = I('function() { this.setValue(""); }')
                                                ))
                             ),
                             div(style = "flex: 1; min-width: 150px; text-align: right;",
                                 selectInput("diagnostics_model", "Model:", choices = NULL)
                             )
                         )
                     ) # end panel-body
                 ) # end panel
          ) # end column
        ), # End fluidRow for item selection
        
        fluidRow(
          # Left Column: Visualization and Analysis
          column(width = 8,
                 # Residual analysis panel
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Residual Analysis"),
                     div(class = "panel-body",
                         div(style = "display: flex; justify-content: flex-end; margin-bottom: 10px;",
                             div(style = "display: flex; align-items: center; gap: 10px;",
                                 selectInput(
                                   "residual_plot_type", "Plot Type:",
                                   choices = c("Time Series", "Histogram", "QQ Plot", "ACF"),
                                   selected = "Time Series", width = "150px"
                                 )
                             )
                         ),
                         withSpinner(plotlyOutput("residual_plot", height = "300px"), type = 8, color = "#00a65a"),
                         div(style = "margin-top: 15px;",
                             fluidRow(
                               column(width = 6,
                                      h4("Residual Statistics"),
                                      withSpinner(verbatimTextOutput("residual_stats"), type = 8, color = "#00a65a")
                               ),
                               column(width = 6,
                                      h4("Tests for Randomness"),
                                      withSpinner(verbatimTextOutput("residual_tests"), type = 8, color = "#00a65a")
                               )
                             )
                         )
                     ) # End panel-body
                 ), # End residual panel
                 
                 # Advanced diagnostics tabbed view
                 tabsetPanel(
                   id = "diagnostics_tabs",
                   type = "tabs",
                   tabPanel(
                     "Model Parameters",
                     div(style = "margin-top: 15px;",
                         withSpinner(verbatimTextOutput("model_parameters"), type = 8, color = "#00a65a")
                     ),
                     hr(),
                     h4("Parameter Stability"),
                     withSpinner(plotlyOutput("parameter_stability", height = "250px"), type = 8, color = "#00a65a")
                   ),
                   tabPanel(
                     "Seasonality Analysis",
                     div(style = "margin-top: 15px;",
                         withSpinner(plotlyOutput("seasonality_plot", height = "400px"), type = 8, color = "#00a65a")
                     ),
                     hr(),
                     div(style = "display: flex; flex-wrap: wrap; gap: 15px;",
                         div(style = "flex: 1; min-width: 250px;",
                             h4("Seasonal Patterns"),
                             withSpinner(verbatimTextOutput("seasonal_patterns"), type = 8, color = "#00a65a")
                         ),
                         div(style = "flex: 1; min-width: 250px;",
                             h4("Strength of Seasonality"),
                             withSpinner(verbatimTextOutput("seasonal_strength"), type = 8, color = "#00a65a")
                         )
                     )
                   ),
                   tabPanel(
                     "Forecast Evaluation",
                     div(style = "margin-top: 15px;",
                         h4("Forecast Error Analysis"),
                         withSpinner(plotlyOutput("forecast_error_plot", height = "250px"), type = 8, color = "#00a65a")
                     ),
                     hr(),
                     div(style = "display: flex; flex-wrap: wrap; gap: 15px;",
                         div(style = "flex: 1; min-width: 250px;",
                             h4("Error Distribution"),
                             withSpinner(plotlyOutput("error_distribution", height = "200px"), type = 8, color = "#00a65a")
                         ),
                         div(style = "flex: 1; min-width: 250px;",
                             h4("Error Statistics"),
                             withSpinner(verbatimTextOutput("error_stats"), type = 8, color = "#00a65a")
                         )
                     )
                   )
                 ) # End tabsetPanel
          ), # End column(width=8)
          
          # Right Column: Summary and Actions
          column(width = 4,
                 # Diagnostic summary panel
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Diagnostic Summary"),
                     div(class = "panel-body",
                         h4("Model Quality"),
                         div(style = "margin-bottom: 15px;",
                             div(style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 5px;",
                                 span("Residual Randomness:"),
                                 span(id = "residual_randomness_badge", class = "badge badge-success", "Good")
                             ),
                             div(class = "progress",
                                 div(class = "progress-bar bg-success", id = "residual_randomness_bar",
                                     role = "progressbar", style = "width: 80%", "aria-valuenow" = "80",
                                     "aria-valuemin" = "0", "aria-valuemax" = "100")
                             )
                         ),
                         div(style = "margin-bottom: 15px;",
                             div(style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 5px;",
                                 span("Parameter Significance:"),
                                 span(id = "parameter_significance_badge", class = "badge badge-success", "Good")
                             ),
                             div(class = "progress",
                                 div(class = "progress-bar bg-success", id = "parameter_significance_bar",
                                     role = "progressbar", style = "width: 75%", "aria-valuenow" = "75",
                                     "aria-valuemin" = "0", "aria-valuemax" = "100")
                             )
                         ),
                         div(style = "margin-bottom: 15px;",
                             div(style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 5px;",
                                 span("Forecast Accuracy:"),
                                 span(id = "forecast_accuracy_badge", class = "badge badge-warning", "Moderate")
                             ),
                             div(class = "progress",
                                 div(class = "progress-bar bg-warning", id = "forecast_accuracy_bar",
                                     role = "progressbar", style = "width: 60%", "aria-valuenow" = "60",
                                     "aria-valuemin" = "0", "aria-valuemax" = "100")
                             )
                         ),
                         div(style = "margin-bottom: 15px;",
                             div(style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 5px;",
                                 span("Overall Model Fit:"),
                                 span(id = "overall_fit_badge", class = "badge badge-success", "Good")
                             ),
                             div(class = "progress",
                                 div(class = "progress-bar bg-success", id = "overall_fit_bar",
                                     role = "progressbar", style = "width: 70%", "aria-valuenow" = "70",
                                     "aria-valuemin" = "0", "aria-valuemax" = "100")
                             )
                         ),
                         hr(),
                         h4("Model Information"),
                         withSpinner(verbatimTextOutput("diagnostics_info"), type = 8, color = "#00a65a")
                     ) # End panel-body
                 ), # End diagnostic summary panel
                 
                 # Model comparison panel
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Model Comparison"),
                     div(class = "panel-body",
                         div(style = "display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 15px;",
                             div(style = "flex: 1; min-width: 100px;",
                                 checkboxInput("compare_arima", "ARIMA", TRUE)
                             ),
                             div(style = "flex: 1; min-width: 100px;",
                                 checkboxInput("compare_ets", "ETS", TRUE)
                             ),
                             div(style = "flex: 1; min-width: 100px;",
                                 checkboxInput("compare_prophet", "Prophet", FALSE)
                             )
                         ),
                         div(style = "margin-bottom: 15px;",
                             actionButton("run_comparison", "Run Comparison", icon = icon("chart-bar"), 
                                          class = "btn-primary btn-block")
                         ),
                         withSpinner(plotlyOutput("comparison_plot", height = "200px"), type = 8, color = "#00a65a"),
                         hr(),
                         h4("Comparison Metrics"),
                         withSpinner(DTOutput("comparison_table"), type = 8, color = "#00a65a")
                     ) # End panel-body
                 ), # End model comparison panel
                 
                 # Export diagnostics panel
                 div(class = "panel panel-primary",
                     div(class = "panel-heading", "Export Diagnostics"),
                     div(class = "panel-body",
                         selectInput("export_diagnostics_format", "Export Format:",
                                     choices = c("PDF Report" = "pdf", "HTML Report" = "html", "Word Document" = "docx"),
                                     selected = "pdf"),
                         div(style = "margin-top: 15px;",
                             downloadButton("download_diagnostics", "Download Diagnostics Report", class = "btn-info btn-block")
                         ),
                         div(style = "margin-top: 15px;",
                             div(class = "alert alert-info", icon("info-circle"),
                                 "The report includes all diagnostic plots and statistics shown on this page.")
                         )
                     ) # End panel-body
                 ) # End export panel
          ) # End column(width=4)
        ) # End main fluidRow
      ) # End fluidPage
    ) # End Diagnostics tabPanel
    
    ,
    
    # ===== Help Tab =====
    tabPanel(
      title = "Help",
      icon = icon("question-circle"),
      value = "help",
      
      fluidPage(
        
        downloadButton("download_help_pdf", "Download Help as PDF", 
                       class = "btn-primary", 
                       style = "margin: 15px 0;"),
        # App overview panel
        div(class = "panel panel-primary",
            div(class = "panel-heading", "Lucent: Time Series Forecasting Guide"),
            div(class = "panel-body",
                div(style = "display: flex; flex-wrap: wrap; gap: 20px; align-items: center;",
                    div(style = "flex: 3; min-width: 300px;",
                        h3("Welcome to Lucent"),
                        p("Lucent is a comprehensive time series forecasting application designed to help you analyze historical data and generate accurate predictions. This application combines powerful statistical methods with an intuitive interface to make forecasting accessible for all experience levels."),
                        h4("Key Features:"),
                        tags$ul(
                          tags$li(HTML("<strong>Multiple Forecasting Methods:</strong> ARIMA, Exponential Smoothing, and Prophet models")),
                          tags$li(HTML("<strong>Data Preprocessing:</strong> Handle missing values, outliers, and transformations")),
                          tags$li(HTML("<strong>Interactive Visualizations:</strong> Explore your data with dynamic plots")),
                          tags$li(HTML("<strong>Model Diagnostics:</strong> Evaluate model performance and forecast accuracy")),
                          tags$li(HTML("<strong>Export Capabilities:</strong> Download results in various formats"))
                        )
                    ),
                    div(style = "flex: 2; min-width: 200px; text-align: center;",
                        icon("chart-line", style = "font-size: 120px; color: #00a65a; opacity: 0.2;"))
                )
            )
        ),
        
        # Step-by-step workflow
        div(class = "panel panel-primary",
            div(class = "panel-heading", "Application Workflow"),
            div(class = "panel-body",
                div(class = "row",
                    div(class = "col-md-12",
                        div(class = "bs-stepper",
                            div(class = "bs-stepper-header",
                                div(class = "step", style = "display: flex; align-items: center; margin-bottom: 20px;",
                                    div(class = "step-circle bg-primary", style = "width: 30px; height: 30px; border-radius: 50%; display: flex; justify-content: center; align-items: center; background-color: #337ab7; color: white; margin-right: 15px;", "1"),
                                    h4("Data Upload", style="margin: 0;")
                                ),
                                div(style = "border-left: 2px dashed #ccc; height: 30px; margin-left: 15px;"),
                                div(class = "step", style = "display: flex; align-items: center; margin-bottom: 20px;",
                                    div(class = "step-circle bg-primary", style = "width: 30px; height: 30px; border-radius: 50%; display: flex; justify-content: center; align-items: center; background-color: #337ab7; color: white; margin-right: 15px;", "2"),
                                    h4("Preprocessing", style="margin: 0;")
                                ),
                                div(style = "border-left: 2px dashed #ccc; height: 30px; margin-left: 15px;"),
                                div(class = "step", style = "display: flex; align-items: center; margin-bottom: 20px;",
                                    div(class = "step-circle bg-primary", style = "width: 30px; height: 30px; border-radius: 50%; display: flex; justify-content: center; align-items: center; background-color: #337ab7; color: white; margin-right: 15px;", "3"),
                                    h4("Forecast Configuration", style="margin: 0;")
                                ),
                                div(style = "border-left: 2px dashed #ccc; height: 30px; margin-left: 15px;"),
                                div(class = "step", style = "display: flex; align-items: center; margin-bottom: 20px;",
                                    div(class = "step-circle bg-primary", style = "width: 30px; height: 30px; border-radius: 50%; display: flex; justify-content: center; align-items: center; background-color: #337ab7; color: white; margin-right: 15px;", "4"),
                                    h4("Results Analysis", style="margin: 0;")
                                ),
                                div(style = "border-left: 2px dashed #ccc; height: 30px; margin-left: 15px;"),
                                div(class = "step", style = "display: flex; align-items: center;",
                                    div(class = "step-circle bg-primary", style = "width: 30px; height: 30px; border-radius: 50%; display: flex; justify-content: center; align-items: center; background-color: #337ab7; color: white; margin-right: 15px;", "5"),
                                    h4("Diagnostics", style="margin: 0;")
                                )
                            )
                        )
                    )
                )
            )
        ),
        
        # Detailed help sections using tabs
        div(class = "panel panel-primary",
            div(class = "panel-heading", "Detailed Instructions"),
            div(class = "panel-body",
                tabsetPanel(
                  id = "help_tabs",
                  type = "tabs",
                  # Data Tab Help
                  tabPanel(
                    "Data",
                    div(style = "margin-top: 15px;",
                        h4("Getting Started with Data"),
                        p("The Data tab is your starting point for any forecasting project. Here you'll upload your time series data and explore its characteristics."),
                        
                        h5("Required Data Format"),
                        p("Your dataset must contain these columns:"),
                        tags$ul(
                          tags$li(HTML("<strong>Date:</strong> Date column in yyyy-mm-dd format (or other standard date formats)")),
                          tags$li(HTML("<strong>Entity_ID:</strong> Unique identifier for each item/product")),
                          tags$li(HTML("<strong>Entity_Name:</strong> Descriptive name for each item")),
                          tags$li(HTML("<strong>Volume:</strong> Numeric values you want to forecast (e.g., sales, demand, counts)"))
                        ),
                        
                        h5("Data Upload Steps"),
                        tags$ol(
                          tags$li("Click the 'Browse...' button in the Data Input section"),
                          tags$li("Select your CSV or Excel file from your computer"),
                          tags$li("Ensure 'File has header row' is checked if your file contains headers"),
                          tags$li("Once uploaded, your data will appear in the Data Preview section")
                        ),
                        
                        h5("Data Template"),
                        p("Not sure about the format? Download our template by clicking the 'Download Template' button."),
                        
                        div(class = "alert alert-info", style = "margin-top: 15px;",
                            icon("info-circle"),
                            HTML("<strong>Tips:</strong>"),
                            tags$ul(
                              tags$li("Review 'Data Preview' to confirm your data loaded correctly"),
                              tags$li("Check 'Summary Statistics' for data overview and potential issues"),
                              tags$li("Examine 'Missing Values' to identify gaps in your data that may need attention")
                            )
                        ),
                        
                        # div(class = "text-center", style = "margin-top: 30px;",
                        #     img(src = "data-tab-example.png", 
                        #         style = "max-width: 90%; border: 1px solid #ddd; border-radius: 4px; padding: 5px;",
                        #         alt = "Data Tab Example")
                        # )
                    )
                  ),
                  
                  # Preprocessing Tab Help
                  tabPanel(
                    "Preprocessing",
                    div(style = "margin-top: 15px;",
                        h4("Data Preprocessing Workflow"),
                        p("Data preprocessing is critical for accurate forecasting. This tab helps you clean and transform your time series data before analysis."),
                        
                        h5("Item Selection"),
                        p("First, select the specific item you want to preprocess from the dropdown menu at the top of the page. You can also view all items together by checking 'Show combined view for all items'."),
                        
                        h5("Key Preprocessing Functions"),
                        
                        div(style = "border-left: 4px solid #00a65a; padding-left: 15px; margin: 15px 0;",
                            h5(HTML("<strong>1. Handling Missing Values</strong>")),
                            p("Missing values can distort your forecasts. Choose a method that fits your data:"),
                            tags$ul(
                              tags$li(HTML("<strong>Linear Interpolation:</strong> Fills gaps with values along a straight line between existing points")),
                              tags$li(HTML("<strong>Forward Fill:</strong> Propagates the last valid value forward")),
                              tags$li(HTML("<strong>Backward Fill:</strong> Uses the next valid value to fill gaps backward")),
                              tags$li(HTML("<strong>Mean/Median Fill:</strong> Replaces missing values with the average or median")),
                              tags$li(HTML("<strong>Remove Rows:</strong> Eliminates rows with missing values (use cautiously)"))
                            ),
                            p("After selecting your method, click 'Apply' to implement it.")
                        ),
                        
                        div(style = "border-left: 4px solid #00a65a; padding-left: 15px; margin: 15px 0;",
                            h5(HTML("<strong>2. Handling Duplicates</strong>")),
                            p("Duplicate entries can skew your analysis:"),
                            tags$ul(
                              tags$li(HTML("<strong>Keep All:</strong> Retain all duplicate entries (default)")),
                              tags$li(HTML("<strong>Keep First/Last:</strong> Keep only the first or last occurrence")),
                              tags$li(HTML("<strong>Aggregate:</strong> Combine duplicates using sum or mean"))
                            )
                        ),
                        
                        div(style = "border-left: 4px solid #00a65a; padding-left: 15px; margin: 15px 0;",
                            h5(HTML("<strong>3. Managing Outliers</strong>")),
                            p("Outliers can significantly impact forecast accuracy:"),
                            tags$ul(
                              tags$li(HTML("<strong>Detection Methods:</strong> IQR, Z-Score, GESD")),
                              tags$li(HTML("<strong>Threshold:</strong> Controls sensitivity of detection")),
                              tags$li(HTML("<strong>Actions:</strong> Keep (highlight only), Remove, Replace with Mean/Median, or Winsorize (cap at percentiles)"))
                            ),
                            p("Check 'Highlight Outliers' in the visualization panel to see detected outliers.")
                        ),
                        
                        div(style = "border-left: 4px solid #00a65a; padding-left: 15px; margin: 15px 0;",
                            h5(HTML("<strong>4. Time Aggregation</strong>")),
                            p("Change the time granularity of your data:"),
                            tags$ul(
                              tags$li(HTML("<strong>Daily to Weekly/Monthly:</strong> Roll up daily data")),
                              tags$li(HTML("<strong>Weekly to Monthly:</strong> Combine weekly observations")),
                              tags$li(HTML("<strong>Custom:</strong> Specify your own period length"))
                            ),
                            p("The aggregation preview helps you visualize the effect before applying.")
                        ),
                        
                        div(style = "border-left: 4px solid #00a65a; padding-left: 15px; margin: 15px 0;",
                            h5(HTML("<strong>5. Data Transformation & Seasonality</strong>")),
                            p("Transform your data to improve forecast accuracy:"),
                            tags$ul(
                              tags$li(HTML("<strong>Transformations:</strong> Log, Square Root, Box-Cox, Z-score, Min-Max Scaling")),
                              tags$li(HTML("<strong>Seasonal Adjustment:</strong> Decompose and optionally remove seasonality"))
                            )
                        ),
                        
                        h5("Final Steps"),
                        p("After applying your preferred preprocessing steps:"),
                        tags$ol(
                          tags$li("Review the 'Applied Preprocessing' summary to confirm all desired changes"),
                          tags$li("Click 'Apply All Changes' to finalize preprocessing"),
                          tags$li("If needed, use 'Reset to Original' to start over"),
                          tags$li("You can download your processed data with 'Download Processed Data'")
                        ),
                        
                        div(class = "alert alert-warning", style = "margin-top: 15px;",
                            icon("exclamation-triangle"),
                            HTML("<strong>Important:</strong> Each preprocessing step is applied immediately when you click its respective 'Apply' button. The preprocessing summary panel shows all steps that have been applied.")
                        )
                    )
                  ),
                  
                  # Forecast Tab Help
                  tabPanel(
                    "Forecast",
                    div(style = "margin-top: 15px;",
                        h4("Configuring and Running Forecasts"),
                        p("The Forecast tab is where you select your forecasting method and configure parameters to generate predictions."),
                        
                        h5("Item Selection"),
                        p("Choose which item to forecast from the dropdown. You can forecast a single item or batch process all items by checking 'Forecast all items'."),
                        
                        h5("Forecasting Methods"),
                        p("Lucent offers three powerful forecasting methods:"),
                        
                        div(class = "row", style = "margin: 20px 0;",
                            div(class = "col-md-4",
                                div(class = "panel panel-default",
                                    div(class = "panel-heading", style = "background-color: #f5f5f5;",
                                        h5(HTML("<strong>ARIMA</strong>"), style = "margin: 0;")
                                    ),
                                    div(class = "panel-body",
                                        p(HTML("<strong>Best for:</strong> Data with clear trends and/or seasonality patterns")),
                                        p(HTML("<strong>Key settings:</strong>")),
                                        tags$ul(
                                          tags$li("Auto ARIMA (recommended for beginners)"),
                                          tags$li("Manual parameter selection (p, d, q)"),
                                          tags$li("Seasonal components (P, D, Q, S)")
                                        ),
                                        p(HTML("<strong>When to use:</strong> When you have stationary data or data that can be made stationary through differencing"))
                                    )
                                )
                            ),
                            div(class = "col-md-4",
                                div(class = "panel panel-default",
                                    div(class = "panel-heading", style = "background-color: #f5f5f5;",
                                        h5(HTML("<strong>Exponential Smoothing</strong>"), style = "margin: 0;")
                                    ),
                                    div(class = "panel-body",
                                        p(HTML("<strong>Best for:</strong> Data with trend and seasonal patterns, especially when recent observations are more important")),
                                        p(HTML("<strong>Key settings:</strong>")),
                                        tags$ul(
                                          tags$li("Auto ETS (recommended)"),
                                          tags$li("Model type (ANN, AAN, AAA, etc.)"),
                                          tags$li("Smoothing parameters (α, β, γ)")
                                        ),
                                        p(HTML("<strong>When to use:</strong> When recent observations should be weighted more heavily than older ones"))
                                    )
                                )
                            ),
                            div(class = "col-md-4",
                                div(class = "panel panel-default",
                                    div(class = "panel-heading", style = "background-color: #f5f5f5;",
                                        h5(HTML("<strong>Prophet</strong>"), style = "margin: 0;")
                                    ),
                                    div(class = "panel-body",
                                        p(HTML("<strong>Best for:</strong> Business time series with multiple seasonal patterns, holidays, and outliers")),
                                        p(HTML("<strong>Key settings:</strong>")),
                                        tags$ul(
                                          tags$li("Changepoint prior scale"),
                                          tags$li("Seasonality types (yearly, weekly, daily)"),
                                          tags$li("Holiday effects")
                                        ),
                                        p(HTML("<strong>When to use:</strong> For complex business forecasting tasks with multiple seasonal patterns and special events"))
                                    )
                                )
                            )
                        ),
                        
                        h5("Forecast Settings"),
                        tags$ul(
                          tags$li(HTML("<strong>Forecast Horizon:</strong> How many periods into the future to forecast")),
                          tags$li(HTML("<strong>Data Frequency:</strong> Time interval of your data (daily, weekly, monthly, etc.)")),
                          tags$li(HTML("<strong>Auto-detect frequency:</strong> Let the application determine the best frequency")),
                          tags$li(HTML("<strong>Prediction Intervals:</strong> Show uncertainty ranges around your forecast")),
                          tags$li(HTML("<strong>Confidence Level:</strong> Adjust the width of prediction intervals (e.g., 80%, 95%)")),
                          tags$li(HTML("<strong>Cross-Validation:</strong> Enable to assess forecast accuracy on historical data"))
                        ),
                        
                        h5("Preview and Run"),
                        p("The forecast preview shows a visualization of what your forecast will look like with current settings. To update the preview with new settings, click 'Update Preview'."),
                        p("When you're satisfied with the configuration, click 'Run Forecast' to generate the forecast. For batch processing, you can specify the number of parallel cores to use."),
                        
                        div(class = "alert alert-success", style = "margin-top: 15px;",
                            icon("lightbulb"),
                            HTML("<strong>Pro Tip:</strong> Start with automatic methods (auto.arima, auto ETS) to get baseline results, then experiment with manual parameters if needed for refinement. The forecast preview helps you quickly assess the impact of parameter changes before running the full forecast.")
                        )
                    )
                  ),
                  
                  # Results Tab Help
                  tabPanel(
                    "Results",
                    div(style = "margin-top: 15px;",
                        h4("Analyzing Forecast Results"),
                        p("After running a forecast, the Results tab provides comprehensive tools to analyze and interpret your predictions."),
                        
                        h5("Performance Metrics"),
                        p("At the top of the tab, you'll see key performance metrics for your forecast:"),
                        tags$ul(
                          tags$li(HTML("<strong>MAE (Mean Absolute Error):</strong> Average absolute difference between forecasted and actual values. Lower is better.")),
                          tags$li(HTML("<strong>RMSE (Root Mean Square Error):</strong> Root of average squared differences, giving more weight to larger errors. Lower is better.")),
                          tags$li(HTML("<strong>MAPE (Mean Absolute Percentage Error):</strong> Percentage representation of error relative to actual values. Lower is better."))
                        ),
                        
                        h5("Forecast Visualization"),
                        p("The main visualization shows your forecast alongside historical data:"),
                        tags$ul(
                          tags$li(HTML("<strong>Plot Type options:</strong> Choose between Line, Line with Points, or Area")),
                          tags$li(HTML("<strong>Prediction Intervals:</strong> Toggle to show/hide the forecast uncertainty range")),
                          tags$li(HTML("<strong>Interactive features:</strong> Hover for exact values, zoom, pan, and download as image"))
                        ),
                        
                        h5("Detailed Views"),
                        p("The tabbed sections below the main plot offer deeper insights:"),
                        
                        div(style = "border-left: 4px solid #3c8dbc; padding-left: 15px; margin: 15px 0;",
                            h5(HTML("<strong>Data Table</strong>")),
                            p("View the numeric forecast data in table format:"),
                            tags$ul(
                              tags$li(HTML("<strong>Forecast Only:</strong> View just the predicted values")),
                              tags$li(HTML("<strong>Historical + Forecast:</strong> See both historical and forecast data together")),
                              tags$li(HTML("<strong>Full Data:</strong> Complete dataset including all metadata"))
                            )
                        ),
                        
                        div(style = "border-left: 4px solid #3c8dbc; padding-left: 15px; margin: 15px 0;",
                            h5(HTML("<strong>Forecast Statistics</strong>")),
                            p("Detailed statistical summary of your forecast, including:"),
                            tags$ul(
                              tags$li("Statistical measures of the forecast values"),
                              tags$li("Model accuracy metrics"),
                              tags$li("Distribution characteristics")
                            )
                        ),
                        
                        div(style = "border-left: 4px solid #3c8dbc; padding-left: 15px; margin: 15px 0;",
                            h5(HTML("<strong>Decomposition</strong>")),
                            p("Visualizes the components of your time series:"),
                            tags$ul(
                              tags$li(HTML("<strong>Trend:</strong> Long-term progression")),
                              tags$li(HTML("<strong>Seasonal:</strong> Recurring patterns")),
                              tags$li(HTML("<strong>Remainder:</strong> Residual variation"))
                            ),
                            p("This helps understand what's driving your data patterns.")
                        ),
                        
                        h5("Model Information"),
                        p("The 'Model Summary' panel on the right shows technical details about your forecast model:"),
                        tags$ul(
                          tags$li("Model parameters and coefficients"),
                          tags$li("Information criteria (AIC, BIC)"),
                          tags$li("Statistical significance of components")
                        ),
                        
                        h5("Actions"),
                        p("Several options are available for working with your results:"),
                        tags$ul(
                          tags$li(HTML("<strong>Export Full Report:</strong> Create a comprehensive report of your forecast")),
                          tags$li(HTML("<strong>Adjust & Re-run Forecast:</strong> Return to the Forecast tab to modify parameters")),
                          tags$li(HTML("<strong>Compare Models:</strong> Go to Diagnostics to evaluate different methods")),
                          tags$li(HTML("<strong>Download Results:</strong> Export your forecast in Excel, CSV, or R Data format"))
                        ),
                        
                        div(class = "alert alert-info", style = "margin-top: 15px;",
                            icon("info-circle"),
                            HTML("<strong>Interpretation Guide:</strong> Generally, a MAPE below 10% indicates excellent forecast accuracy, 10-20% is good, 20-30% is acceptable, and above 30% suggests the forecast may need improvement. Consider trying different preprocessing steps or forecasting methods if accuracy is poor.")
                        )
                    )
                  ),
                  
                  # Diagnostics Tab Help
                  tabPanel(
                    "Diagnostics",
                    div(style = "margin-top: 15px;",
                        h4("Advanced Model Diagnostics"),
                        p("The Diagnostics tab offers powerful tools to evaluate model quality, understand limitations, and compare different forecasting approaches."),
                        
                        h5("Residual Analysis"),
                        p("Residuals are the differences between actual and fitted values. Ideally, residuals should be random with no pattern:"),
                        tags$ul(
                          tags$li(HTML("<strong>Time Series plot:</strong> Shows residuals over time - look for random scattering around zero")),
                          tags$li(HTML("<strong>Histogram:</strong> Displays distribution - ideally bell-shaped and centered at zero")),
                          tags$li(HTML("<strong>QQ Plot:</strong> Tests for normality - points should follow the diagonal line")),
                          tags$li(HTML("<strong>ACF:</strong> Autocorrelation function - values should stay within confidence bands"))
                        ),
                        
                        p("The 'Residual Statistics' and 'Tests for Randomness' sections provide formal statistical assessments of residual quality."),
                        
                        h5("Model Parameters"),
                        p("Examine the stability and significance of your model's parameters:"),
                        tags$ul(
                          tags$li(HTML("<strong>Parameter details:</strong> View coefficient values, standard errors, and significance")),
                          tags$li(HTML("<strong>Parameter stability:</strong> Shows how parameters change when estimated on different subsets of data"))
                        ),
                        
                        h5("Seasonality Analysis"),
                        p("Understand seasonal patterns in your time series:"),
                        tags$ul(
                          tags$li(HTML("<strong>Seasonal patterns:</strong> Visualize recurring cycles (yearly, monthly, weekly, etc.)")),
                          tags$li(HTML("<strong>Seasonal strength:</strong> Quantifies how important seasonality is in your data"))
                        ),
                        
                        h5("Forecast Evaluation"),
                        p("Assess forecast accuracy and error characteristics:"),
                        tags$ul(
                          tags$li(HTML("<strong>Error analysis:</strong> Distribution and patterns in forecast errors")),
                          tags$li(HTML("<strong>Error statistics:</strong> Detailed metrics on model performance"))
                        ),
                        
                        h5("Model Comparison"),
                        p("Compare different forecasting methods to find the best one for your data:"),
                        tags$ol(
                          tags$li("Select which models to compare (ARIMA, ETS, Prophet)"),
                          tags$li("Click 'Run Comparison' to perform cross-validation"),
                          tags$li("View comparison metrics and error distributions to identify the best performer")
                        ),
                        
                        h5("Quality Indicators"),
                        p("The diagnostic summary provides at-a-glance quality assessments:"),
                        tags$ul(
                          tags$li(HTML("<strong>Residual Randomness:</strong> Whether residuals show desirable random properties")),
                          tags$li(HTML("<strong>Parameter Significance:</strong> Whether model parameters are statistically meaningful")),
                          tags$li(HTML("<strong>Forecast Accuracy:</strong> Overall predictive performance")),
                          tags$li(HTML("<strong>Overall Model Fit:</strong> Combined quality assessment"))
                        ),
                        
                        h5("Report Export"),
                        p("You can download a comprehensive diagnostics report in various formats for documentation and sharing."),
                        
                        div(class = "alert alert-warning", style = "margin-top: 15px;",
                            icon("exclamation-triangle"),
                            HTML("<strong>Advanced Users:</strong> The diagnostics tab is particularly valuable for statistical analysts and data scientists who need to understand model assumptions and limitations. For basic forecasting needs, you may focus primarily on the Results tab.")
                        )
                    )
                  ),
                  
                  # FAQ Panel
                  tabPanel(
                    "FAQ",
                    div(style = "margin-top: 15px;",
                        h4("Frequently Asked Questions"),
                        
                        # Use Bootstrap collapse for FAQ items
                        div(class = "panel-group", id = "faq_accordion",
                            
                            # FAQ Item 1
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#faq_accordion" href="#faq1">What file formats are supported for data upload?</a>')
                                    )
                                ),
                                div(id = "faq1", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        p("Lucent supports CSV (.csv) and Excel (.xlsx, .xls) file formats. The file must contain columns for Date, Entity_ID, Entity_Name, and Volume. Make sure your Date column is in a standard date format (e.g., YYYY-MM-DD) and Volume values are numeric. If you're unsure about the required format, download the template from the Data tab.")
                                    )
                                )
                            ),
                            
                            # FAQ Item 2
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#faq_accordion" href="#faq2">Which forecasting method should I choose?</a>')
                                    )
                                ),
                                div(id = "faq2", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        tags$ul(
                                          tags$li(HTML("<strong>ARIMA:</strong> Best for data with clear trends and/or seasonality. Works well with stationary data or after applying differencing.")),
                                          tags$li(HTML("<strong>Exponential Smoothing:</strong> Excellent for data with trend and seasonality, especially when recent observations should have more weight than older ones.")),
                                          tags$li(HTML("<strong>Prophet:</strong> Ideal for business time series with multiple seasonal patterns, holidays, and outliers. Very robust to missing data and shifts in trend."))
                                        ),
                                        p("If you're unsure, try using the Model Comparison feature in the Diagnostics tab, which will run cross-validation to help identify the best method for your specific data.")
                                    )
                                )
                            ),
                            
                            # FAQ Item 3
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#faq_accordion" href="#faq3">How do I interpret the forecast performance metrics?</a>')
                                    )
                                ),
                                div(id = "faq3", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        tags$ul(
                                          tags$li(HTML("<strong>MAE (Mean Absolute Error):</strong> Average absolute difference between forecasted and actual values. Measured in the same units as your data. Lower is better.")),
                                          tags$li(HTML("<strong>RMSE (Root Mean Square Error):</strong> Similar to MAE but gives more weight to large errors. Also in the same units as your data. Lower is better.")),
                                          tags$li(HTML("<strong>MAPE (Mean Absolute Percentage Error):</strong> Average percentage difference between forecasted and actual values. Generally, MAPE < 10% is excellent, 10-20% is good, 20-30% is acceptable, and >30% may indicate poor forecast quality."))
                                        ),
                                        p("When comparing models, choose the one with the lowest metrics values, with particular attention to MAPE as it's scale-independent.")
                                    )
                                )
                            ),
                            
                            # FAQ Item 4
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#faq_accordion" href="#faq4">How should I handle outliers in my data?</a>')
                                    )
                                ),
                                div(id = "faq4", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        p("Outliers can significantly impact forecast accuracy. In the Preprocessing tab, you can handle outliers with these approaches:"),
                                        tags$ol(
                                          tags$li(HTML("<strong>Keep:</strong> Use when outliers represent genuine events you want the model to learn from (e.g., promotional periods, special events)")),
                                          tags$li(HTML("<strong>Remove:</strong> Use when outliers are data errors or extremely unusual events you don't want to affect forecasts")),
                                          tags$li(HTML("<strong>Replace with Mean/Median:</strong> Good middle-ground approach that retains the time point but reduces extreme values")),
                                          tags$li(HTML("<strong>Winsorize:</strong> Caps extreme values at percentile boundaries; useful for preserving the direction of outliers while reducing their impact"))
                                        ),
                                        p("First use 'Highlight Outliers' in the visualization to see outliers, then decide on the appropriate approach based on your domain knowledge about what caused them.")
                                    )
                                )
                            ),
                            
                            # FAQ Item 5
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#faq_accordion" href="#faq5">What is Cross-Validation and when should I use it?</a>')
                                    )
                                ),
                                div(id = "faq5", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        p("Cross-Validation (CV) is a technique that tests how well your forecast model performs on unseen data by using historical data to simulate future forecasts. In time series, this means training on an early portion of your data and testing on later portions."),
                                        p("You should enable Cross-Validation when:"),
                                        tags$ul(
                                          tags$li("You want to compare multiple forecasting methods objectively"),
                                          tags$li("You need to ensure your model generalizes well to new data"),
                                          tags$li("You want a realistic assessment of forecast accuracy beyond in-sample fit")
                                        ),
                                        p("CV requires sufficient historical data (generally 30+ observations) to provide meaningful results. The Diagnostics tab's Model Comparison feature uses CV to help you select the best forecasting method.")
                                    )
                                )
                            ),
                            
                            # FAQ Item 6
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#faq_accordion" href="#faq6">How far ahead can I forecast reliably?</a>')
                                    )
                                ),
                                div(id = "faq6", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        p("The reliable forecast horizon depends on several factors:"),
                                        tags$ul(
                                          tags$li(HTML("<strong>Data quality:</strong> Higher quality data (fewer missing values, outliers) enables longer horizons")),
                                          tags$li(HTML("<strong>Historical data amount:</strong> Generally, you need at least 3-4 times more historical data than your forecast horizon")),
                                          tags$li(HTML("<strong>Series stability:</strong> More stable patterns allow longer forecasts")),
                                          tags$li(HTML("<strong>Forecast method:</strong> Some methods handle longer horizons better than others"))
                                        ),
                                        p("As a rule of thumb, forecast accuracy typically deteriorates the further into the future you predict. For most business time series, forecasts beyond 6-12 periods carry increasing uncertainty. Use the prediction intervals to gauge forecast reliability - wider intervals indicate greater uncertainty.")
                                    )
                                )
                            ),
                            
                            # FAQ Item 7
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#faq_accordion" href="#faq7">Why does my forecast have wide prediction intervals?</a>')
                                    )
                                ),
                                div(id = "faq7", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        p("Wide prediction intervals indicate high forecast uncertainty, which can be caused by:"),
                                        tags$ul(
                                          tags$li("High volatility or randomness in your historical data"),
                                          tags$li("Insufficient historical data relative to forecast horizon"),
                                          tags$li("Presence of outliers or structural changes"),
                                          tags$li("Weak or changing patterns that are difficult to model")
                                        ),
                                        p("To reduce prediction interval width:"),
                                        tags$ol(
                                          tags$li("Try preprocessing to remove outliers or smooth your data"),
                                          tags$li("Consider aggregating to a higher level (e.g., weekly instead of daily)"),
                                          tags$li("Use transformations like log or Box-Cox to stabilize variance"),
                                          tags$li("Experiment with different forecasting methods")
                                        )
                                    )
                                )
                            ),
                            
                            # FAQ Item 8
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#faq_accordion" href="#faq8">How do I export and share my forecast results?</a>')
                                    )
                                ),
                                div(id = "faq8", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        p("Lucent provides several options for exporting and sharing results:"),
                                        tags$ul(
                                          tags$li(HTML("<strong>Download Results:</strong> On the Results tab, use the 'Download Results' button to export in Excel, CSV, or R data format")),
                                          tags$li(HTML("<strong>Export Full Report:</strong> Create a comprehensive report with forecast details, charts, and statistics")),
                                          tags$li(HTML("<strong>Download Diagnostics Report:</strong> On the Diagnostics tab, generate a technical report focused on model quality")),
                                          tags$li(HTML("<strong>Data Visualizations:</strong> All plots have download buttons that let you save them as PNG images"))
                                        ),
                                        p("For best results when sharing with stakeholders, the Excel export or full report options provide the most comprehensive information in accessible formats.")
                                    )
                                )
                            )
                        )
                    )
                  ),
                  
                  # Tips & Best Practices
                  tabPanel(
                    "Best Practices",
                    div(style = "margin-top: 15px;",
                        h4("Tips for Effective Forecasting"),
                        
                        h5("Data Preparation"),
                        tags$ul(
                          tags$li(HTML("<strong>Sufficient history:</strong> Aim for at least 3-4 times more historical data than your forecast horizon")),
                          tags$li(HTML("<strong>Consistent frequency:</strong> Try to maintain the same observation frequency throughout your dataset")),
                          tags$li(HTML("<strong>Handle outliers carefully:</strong> Identify and address outliers before forecasting")),
                          tags$li(HTML("<strong>Address missing values:</strong> Use appropriate imputation methods based on your data patterns"))
                        ),
                        
                        h5("Method Selection"),
                        tags$ul(
                          tags$li(HTML("<strong>Try multiple methods:</strong> Use the Model Comparison feature to test different approaches")),
                          tags$li(HTML("<strong>Consider data characteristics:</strong> Match the method to your data's patterns (trend, seasonality, etc.)")),
                          tags$li(HTML("<strong>Start simple:</strong> Begin with automatic methods before fine-tuning parameters")),
                          tags$li(HTML("<strong>Evaluate statistically:</strong> Use the Diagnostics tab to ensure model assumptions are valid"))
                        ),
                        
                        h5("Forecast Evaluation"),
                        tags$ul(
                          tags$li(HTML("<strong>Use cross-validation:</strong> Enable CV to get more reliable accuracy metrics")),
                          tags$li(HTML("<strong>Consider multiple metrics:</strong> Don't rely solely on one performance measure")),
                          tags$li(HTML("<strong>Check residuals:</strong> Verify they're random with no clear patterns")),
                          tags$li(HTML("<strong>Examine prediction intervals:</strong> Ensure they provide realistic uncertainty estimates"))
                        ),
                        
                        h5("Common Pitfalls to Avoid"),
                        div(class = "row",
                            div(class = "col-md-6",
                                div(class = "alert alert-danger",
                                    icon("exclamation-circle"),
                                    HTML("<strong>Overfitting</strong><br>Adding too many parameters can make your model fit historical data well but perform poorly on future data. Use cross-validation to detect this issue.")
                                )
                            ),
                            div(class = "col-md-6",
                                div(class = "alert alert-danger",
                                    icon("exclamation-circle"),
                                    HTML("<strong>Ignoring Diagnostics</strong><br>Poor residual patterns often indicate an inadequate model. Always check the Diagnostics tab to ensure your model meets statistical assumptions.")
                                )
                            )
                        ),
                        div(class = "row",
                            div(class = "col-md-6",
                                div(class = "alert alert-danger",
                                    icon("exclamation-circle"),
                                    HTML("<strong>Too Long Horizon</strong><br>Forecasting too far into the future leads to unreliable predictions. Limit your horizon to a reasonable range based on your data amount and stability.")
                                )
                            ),
                            div(class = "col-md-6",
                                div(class = "alert alert-danger",
                                    icon("exclamation-circle"),
                                    HTML("<strong>Disregarding Outliers</strong><br>Failing to properly address outliers can severely distort forecasts. Always examine and handle outliers appropriately in preprocessing.")
                                )
                            )
                        ),
                        
                        h5("Industry-Specific Considerations"),
                        div(class = "panel-group", id = "industry_accordion",
                            
                            # Retail forecasting
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#industry_accordion" href="#retail">Retail & Sales Forecasting</a>')
                                    )
                                ),
                                div(id = "retail", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        tags$ul(
                                          tags$li("Consider using Prophet to handle holidays and promotional events"),
                                          tags$li("Pay attention to weekly and yearly seasonality patterns"),
                                          tags$li("Consider separate models for different product categories"),
                                          tags$li("Use preprocessing to handle stock-outs (zero values)")
                                        )
                                    )
                                )
                            ),
                            
                            # Financial forecasting
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#industry_accordion" href="#finance">Financial Time Series</a>')
                                    )
                                ),
                                div(id = "finance", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        tags$ul(
                                          tags$li("Financial data often requires transformation (e.g., log returns)"),
                                          tags$li("ARIMA models often work well for financial data"),
                                          tags$li("Pay special attention to volatility patterns"),
                                          tags$li("Consider shorter forecast horizons due to high uncertainty")
                                        )
                                    )
                                )
                            ),
                            
                            # Energy forecasting
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#industry_accordion" href="#energy">Energy & Utility Demand</a>')
                                    )
                                ),
                                div(id = "energy", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        tags$ul(
                                          tags$li("Energy data often has multiple seasonal patterns (daily, weekly, yearly)"),
                                          tags$li("Prophet works well for capturing complex seasonality"),
                                          tags$li("Weather effects may need to be considered as external factors"),
                                          tags$li("Separate weekday/weekend models may improve accuracy")
                                        )
                                    )
                                )
                            ),
                            
                            # Supply chain
                            div(class = "panel panel-default",
                                div(class = "panel-heading",
                                    h5(class = "panel-title",
                                       HTML('<a data-toggle="collapse" data-parent="#industry_accordion" href="#supply">Supply Chain & Inventory</a>')
                                    )
                                ),
                                div(id = "supply", class = "panel-collapse collapse",
                                    div(class = "panel-body",
                                        tags$ul(
                                          tags$li("Consider using Exponential Smoothing for stable products"),
                                          tags$li("Pay attention to lead time variability"),
                                          tags$li("Aggregate forecasts for more stable predictions"),
                                          tags$li("Use prediction intervals to set safety stock levels")
                                        )
                                    )
                                )
                            )
                        )
                    )
                  ),
                  
                  # Methods & Terminology
                  tabPanel(
                    "Methods & Terms",
                    div(style = "margin-top: 15px;",
                        div(class = "row",
                            div(class = "col-md-6",
                                h4("Forecasting Methods Explained"),
                                
                                h5("ARIMA"),
                                p(HTML("ARIMA (Auto-Regressive Integrated Moving Average) models combine three components:")),
                                tags$ul(
                                  tags$li(HTML("<strong>AR (Auto-Regressive):</strong> Uses the relationship between an observation and previous observations")),
                                  tags$li(HTML("<strong>I (Integrated):</strong> Applies differencing to make the time series stationary")),
                                  tags$li(HTML("<strong>MA (Moving Average):</strong> Uses the relationship between an observation and residual errors from a moving average model"))
                                ),
                                p(HTML("ARIMA models are specified as ARIMA(p,d,q) where:")),
                                tags$ul(
                                  tags$li("p = Order of the AR term (how many lags)"),
                                  tags$li("d = Order of differencing (how many times to difference)"),
                                  tags$li("q = Order of the MA term (how many lagged forecast errors)")
                                ),
                                p(HTML("Seasonal ARIMA adds seasonal components: ARIMA(p,d,q)(P,D,Q)m, where m is the seasonal period.")),
                                
                                h5("Exponential Smoothing"),
                                p(HTML("Exponential Smoothing applies exponentially decreasing weights to past observations. Different variations handle different patterns:")),
                                tags$ul(
                                  tags$li(HTML("<strong>Simple Exponential Smoothing:</strong> For data with no clear trend or seasonality")),
                                  tags$li(HTML("<strong>Holt's Linear Method:</strong> For data with trend but no seasonality")),
                                  tags$li(HTML("<strong>Holt-Winters Method:</strong> For data with both trend and seasonality"))
                                ),
                                p(HTML("ETS models specify the Error, Trend, and Seasonal components as Additive (A), Multiplicative (M), or None (N).")),
                                
                                h5("Prophet"),
                                p(HTML("Prophet is a procedure for forecasting time series data developed by Facebook. Key features include:")),
                                tags$ul(
                                  tags$li("Handles missing data and outliers automatically"),
                                  tags$li("Detects trend changes with automatic changepoint detection"),
                                  tags$li("Accommodates multiple seasonal patterns"),
                                  tags$li("Incorporates holidays and special events"),
                                  tags$li("Works well with business data with weekly/yearly patterns")
                                )
                            ),
                            
                            div(class = "col-md-6",
                                h4("Forecasting Terminology"),
                                div(style = "height: 550px; overflow-y: auto;",
                                    tags$dl(
                                      tags$dt("Autocorrelation"),
                                      tags$dd("Correlation between observations of a time series separated by k time units."),
                                      
                                      tags$dt("AIC/BIC"),
                                      tags$dd("Information criteria used to compare models. Lower values indicate better fit balanced with model simplicity."),
                                      
                                      tags$dt("Box-Cox Transformation"),
                                      tags$dd("A family of power transformations that can help stabilize variance and make data more normal."),
                                      
                                      tags$dt("Changepoint"),
                                      tags$dd("A point in time where the underlying trend of a time series changes."),
                                      
                                      tags$dt("Cross-Validation"),
                                      tags$dd("Technique to evaluate model performance by testing it on multiple subsets of data."),
                                      
                                      tags$dt("Decomposition"),
                                      tags$dd("Breaking a time series into components: trend, seasonality, and residual."),
                                      
                                      tags$dt("Differencing"),
                                      tags$dd("Taking the difference between consecutive observations to make a series stationary."),
                                      
                                      tags$dt("Forecast Horizon"),
                                      tags$dd("Number of time periods into the future for which forecasts are generated."),
                                      
                                      tags$dt("Heteroscedasticity"),
                                      tags$dd("When the variability of a time series is not constant over time."),
                                      
                                      tags$dt("Ljung-Box Test"),
                                      tags$dd("Statistical test to determine if residuals exhibit significant autocorrelation."),
                                      
                                      tags$dt("MAE (Mean Absolute Error)"),
                                      tags$dd("Average of absolute errors between forecasted and actual values."),
                                      
                                      tags$dt("MAPE (Mean Absolute Percentage Error)"),
                                      tags$dd("Average of absolute percentage errors between forecasted and actual values."),
                                      
                                      tags$dt("Residuals"),
                                      tags$dd("Differences between observed values and values predicted by a model."),
                                      
                                      tags$dt("RMSE (Root Mean Square Error)"),
                                      tags$dd("Square root of the average of squared differences between forecasted and actual values."),
                                      
                                      tags$dt("Seasonality"),
                                      tags$dd("Regular pattern that repeats over a fixed period (daily, weekly, monthly, etc.)."),
                                      
                                      tags$dt("Stationarity"),
                                      tags$dd("Property where statistical properties like mean and variance don't change over time."),
                                      
                                      tags$dt("Time Series"),
                                      tags$dd("Sequence of data points in time order, typically with equal intervals between observations."),
                                      
                                      tags$dt("Trend"),
                                      tags$dd("Long-term increase or decrease in the data."),
                                      
                                      tags$dt("Winsorizing"),
                                      tags$dd("Transforming statistics by limiting extreme values to reduce the effect of outliers.")
                                    )
                                )
                            )
                        )
                    )
                  ),
                  
                )
            )
        ),
        
      )
    ),
    
    footer = tags$div(
      class = "container-fluid",
      style = "margin-top: 20px; padding: 10px; background-color: #f5f5f5; text-align: center; border-top: 1px solid #ddd;",
      tags$p(
        "Lucent Forecasting Application © 2025",
        style = "margin-bottom: 5px;"
      ),
      # tags$p(
      #   "App Visits: ",
      #   tags$span(id = "visit_counter", "Loading..."),
      #   style = "font-size: 90%; color: #666;"
      # )
    )
    
    
    # ----- Other tabPanels would go here -----
    
  ) # End navbarPage
  
  
  
  
  
  
  
  
  
  
  
  
  
) # End tagList











# Libraries needed for server logic (ensure they are listed here too)
library(shiny)
library(dplyr)
library(tidyr)
library(lubridate)
library(forecast) # Not needed for Data tab logic
library(tseries) # Not needed for Data tab logic
library(zoo) # Not needed for Data tab logic
library(readxl)
library(writexl)
library(ggplot2)
library(prophet) # Not needed for Data tab logic
library(lmtest) # Not needed for Data tab logic
library(DT)
library(shinycssloaders)
library(tools) # For file_ext
library(naniar) # For missing plot (optional, add check)


# SERVER LOGIC - DATA TAB ONLY
server <- function(input, output, session) {
  
  
  options(encoding = "UTF-8")
  Sys.setlocale("LC_ALL", "en_US.UTF-8") # Or another appropriate locale that supports Arabic
  
  
  # Set working directory (Consider if this is needed or if relative paths are better)
  # setwd(dir = 'c:/Users/aleym/Desktop/Lucent')
  
  
  # Add at the beginning of server function
  # Create a reactiveValues to store counters
  app_counters <- reactiveValues(visits = 0)
  
  # # Initialize the counter when the app starts
  # observe({
  #   # This is a simple in-memory counter
  #   # It will reset when the server restarts
  #   app_counters$visits <- app_counters$visits + 1
  #   # Update the UI
  #   output$visit_counter <- renderText({ app_counters$visits })
  # })
  # 
  # # Add this to the server function
  # # Create a function to read/write visit count
  # read_visit_count <- function() {
  #   count_file <- "visit_count.txt"
  #   if (file.exists(count_file)) {
  #     count <- as.numeric(readLines(count_file))
  #     if (is.na(count)) count <- 0
  #     return(count)
  #   } else {
  #     return(0)
  #   }
  # }
  # write_visit_count <- function(count) {
  #   count_file <- "visit_count.txt"
  #   writeLines(as.character(count), count_file)
  # }
  # 
  # # Initialize the counter when the app starts
  # observe({
  #   # Read current count
  #   current_count <- read_visit_count()
  #   # Increment count
  #   new_count <- current_count + 1
  #   # Write back to file
  #   write_visit_count(new_count)
  #   # Update reactive value
  #   app_counters$visits <- new_count
  #   # Update the UI
  #   output$visit_counter <- renderText({ app_counters$visits })
  # })
  
  
  # Reactive values for storing data and results (Retained structure)
  rv <- reactiveValues(
    data = NULL,
    # Original uploaded data
    processed_data = NULL,
    # Data after preprocessing (initialized here)
    outliers = NULL,
    # Detected outliers
    forecast_results = NULL,
    # Forecast results (combined dataframe)
    model_objects = list(),
    # Store model objects
    performance_metrics = list(),
    # Performance metrics
    error_message = NULL,
    # Error messages
    preprocessing_steps = list(),
    # Track preprocessing steps applied
    current_entity = NULL,
    # Currently selected item
    data_loaded = FALSE,
    # Flag for data loading status
    forecast_generated = FALSE,
    # Flag for forecast status
    comparison_forecasts = NULL,
    # For Diagnostics model comparison plot
    comparison_metrics = NULL,
    # For Diagnostics model comparison table
    comparison_models = list()  # Store comparison models if needed later
  )
  
  
  # ===== NEW: Prophet Parameter Auto-Optimization =====
  # Enable/disable Prophet sliders based on auto-optimization checkbox
  observeEvent(input$auto_optimize_prophet, {
    if (input$auto_optimize_prophet) {
      # Disable sliders when auto-optimization is on
      shinyjs::disable("changepoint_prior")
      shinyjs::disable("seasonality_prior")
      
      # Update help text to show auto-optimization status
      shinyjs::html("changepoint_help", "Auto-optimized based on data volatility and trend changes.")
      shinyjs::html("seasonality_help", "Auto-optimized based on seasonal strength and frequency.")
      
      # Add visual indication that parameters are being auto-calculated
      shinyjs::addClass("changepoint_prior", "auto-optimized")
      shinyjs::addClass("seasonality_prior", "auto-optimized")
      
    } else {
      # Enable sliders when auto-optimization is off
      shinyjs::enable("changepoint_prior")
      shinyjs::enable("seasonality_prior")
      
      # Reset to original help text
      shinyjs::html("changepoint_help", "Controls trend flexibility. Higher values = more flexible trends.")
      shinyjs::html("seasonality_help", "Controls seasonal pattern flexibility. Higher values = more flexible seasonality.")
      
      # Remove visual indication
      shinyjs::removeClass("changepoint_prior", "auto-optimized")
      shinyjs::removeClass("seasonality_prior", "auto-optimized")
    }
  }, ignoreInit = TRUE)
  
  
  # ===== Prophet Parameter Optimization Functions =====
  
  # Main function to calculate optimal Prophet parameters
  calculate_prophet_parameters <- function(entity_data) {
    
    # Ensure we have enough data
    if (nrow(entity_data) < 15) {
      return(list(
        changepoint_prior = 0.05,  # Conservative defaults
        seasonality_prior = 10,
        reasoning = "Insufficient data - using conservative defaults"
      ))
    }
    
    tryCatch({
      # Calculate volatility metrics
      volatility_metrics <- calculate_volatility_metrics(entity_data)
      
      # Calculate seasonal strength
      seasonal_metrics <- calculate_seasonal_strength(entity_data)
      
      # Determine optimal parameters
      changepoint_prior <- determine_changepoint_prior(volatility_metrics)
      seasonality_prior <- determine_seasonality_prior(seasonal_metrics)
      
      # Create reasoning explanation
      reasoning <- generate_parameter_reasoning(volatility_metrics, seasonal_metrics, 
                                                changepoint_prior, seasonality_prior)
      
      return(list(
        changepoint_prior = changepoint_prior,
        seasonality_prior = seasonality_prior,
        reasoning = reasoning,
        volatility_cv = volatility_metrics$cv,
        seasonal_strength = seasonal_metrics$strength
      ))
      
    }, error = function(e) {
      warning(paste("Parameter optimization failed:", e$message))
      return(list(
        changepoint_prior = 0.05,
        seasonality_prior = 10,
        reasoning = paste("Optimization failed:", e$message, "- using defaults")
      ))
    })
  }
  
  # Calculate data volatility metrics
  calculate_volatility_metrics <- function(entity_data) {
    
    # Remove NA values and ensure we have numeric data
    volume_clean <- entity_data$Volume[!is.na(entity_data$Volume) & is.finite(entity_data$Volume)]
    
    if (length(volume_clean) < 5) {
      return(list(cv = 0.2, volatility_level = "unknown"))
    }
    
    # Calculate coefficient of variation
    mean_vol <- mean(volume_clean)
    sd_vol <- sd(volume_clean)
    cv <- if (mean_vol > 0) sd_vol / mean_vol else 0
    
    # Calculate additional volatility indicators
    # 1. Percentage of large changes (>20% change from previous period)
    if (length(volume_clean) > 1) {
      changes <- abs(diff(volume_clean)) / volume_clean[-length(volume_clean)]
      large_changes_pct <- sum(changes > 0.2, na.rm = TRUE) / length(changes)
    } else {
      large_changes_pct <- 0
    }
    
    # 2. Range relative to mean
    range_ratio <- if (mean_vol > 0) (max(volume_clean) - min(volume_clean)) / mean_vol else 0
    
    # Determine volatility level
    volatility_level <- case_when(
      cv < 0.1 ~ "very_low",
      cv < 0.3 ~ "low", 
      cv < 0.6 ~ "moderate",
      cv < 1.0 ~ "high",
      TRUE ~ "very_high"
    )
    
    return(list(
      cv = cv,
      large_changes_pct = large_changes_pct,
      range_ratio = range_ratio,
      volatility_level = volatility_level
    ))
  }
  
  # Calculate seasonal strength using STL decomposition
  calculate_seasonal_strength <- function(entity_data) {
    
    # Get frequency for this item
    freq_details <- detect_frequency(entity_data$Date)
    ts_freq <- freq_details$freq_numeric
    
    # Default values for non-seasonal data
    if (ts_freq <= 1 || nrow(entity_data) < 2 * ts_freq + 1) {
      return(list(
        strength = 0,
        seasonal_level = "none",
        freq_unit = freq_details$freq_unit
      ))
    }
    
    tryCatch({
      # Create time series object
      volume_clean <- entity_data$Volume[!is.na(entity_data$Volume)]
      ts_data <- ts(volume_clean, frequency = ts_freq)
      
      if (length(ts_data) < 2 * ts_freq + 1) {
        return(list(strength = 0, seasonal_level = "none", freq_unit = freq_details$freq_unit))
      }
      
      # Perform STL decomposition
      decomp_stl <- stl(ts_data, s.window = "periodic", na.action = na.omit)
      
      # Calculate seasonal strength
      seasonal_comp <- seasonal(decomp_stl)
      remainder_comp <- remainder(decomp_stl)
      
      var_seasonal <- var(seasonal_comp, na.rm = TRUE)
      var_remainder <- var(remainder_comp, na.rm = TRUE)
      
      if (is.na(var_remainder) || var_remainder < 1e-9) {
        seasonal_strength <- 0
      } else {
        var_season_rem <- var(seasonal_comp + remainder_comp, na.rm = TRUE)
        seasonal_strength <- max(0, 1 - var_remainder / var_season_rem)
      }
      
      # Determine seasonal level
      seasonal_level <- case_when(
        seasonal_strength < 0.1 ~ "very_weak",
        seasonal_strength < 0.3 ~ "weak",
        seasonal_strength < 0.6 ~ "moderate", 
        seasonal_strength < 0.8 ~ "strong",
        TRUE ~ "very_strong"
      )
      
      return(list(
        strength = seasonal_strength,
        seasonal_level = seasonal_level,
        freq_unit = freq_details$freq_unit,
        var_seasonal = var_seasonal,
        var_remainder = var_remainder
      ))
      
    }, error = function(e) {
      return(list(
        strength = 0, 
        seasonal_level = "unknown", 
        freq_unit = freq_details$freq_unit
      ))
    })
  }
  
  # Determine optimal changepoint prior based on volatility
  determine_changepoint_prior <- function(volatility_metrics) {
    
    cv <- volatility_metrics$cv
    volatility_level <- volatility_metrics$volatility_level
    large_changes_pct <- volatility_metrics$large_changes_pct
    
    # Base changepoint prior on volatility level
    base_prior <- case_when(
      volatility_level == "very_low" ~ 0.01,   # Very stable data
      volatility_level == "low" ~ 0.02,        # Stable data  
      volatility_level == "moderate" ~ 0.05,   # Default Prophet value
      volatility_level == "high" ~ 0.15,       # Volatile data
      volatility_level == "very_high" ~ 0.3,   # Very volatile data
      TRUE ~ 0.05  # Fallback
    )
    
    # Adjust based on frequency of large changes
    if (large_changes_pct > 0.3) {
      base_prior <- base_prior * 1.5  # More changepoints needed
    } else if (large_changes_pct < 0.1) {
      base_prior <- base_prior * 0.7  # Fewer changepoints needed
    }
    
    # Ensure within reasonable bounds
    changepoint_prior <- pmax(0.001, pmin(0.5, base_prior))
    
    return(round(changepoint_prior, 3))
  }
  
  # Determine optimal seasonality prior based on seasonal strength
  determine_seasonality_prior <- function(seasonal_metrics) {
    
    strength <- seasonal_metrics$strength
    seasonal_level <- seasonal_metrics$seasonal_level
    freq_unit <- seasonal_metrics$freq_unit
    
    # Base seasonality prior on seasonal strength
    base_prior <- case_when(
      seasonal_level == "very_weak" ~ 1,      # Minimal seasonality
      seasonal_level == "weak" ~ 3,           # Light seasonality
      seasonal_level == "moderate" ~ 10,      # Default Prophet value  
      seasonal_level == "strong" ~ 25,        # Strong seasonality
      seasonal_level == "very_strong" ~ 40,   # Very strong seasonality
      TRUE ~ 10  # Fallback
    )
    
    # Adjust based on frequency type
    if (freq_unit == "day") {
      base_prior <- base_prior * 1.2  # Daily data often needs more flexibility
    } else if (freq_unit == "month") {
      base_prior <- base_prior * 0.8  # Monthly data often more stable
    }
    
    # Ensure within reasonable bounds
    seasonality_prior <- pmax(0.01, pmin(50, base_prior))
    
    return(round(seasonality_prior, 1))
  }
  
  # Generate human-readable reasoning for parameter choices
  generate_parameter_reasoning <- function(volatility_metrics, seasonal_metrics, 
                                           changepoint_prior, seasonality_prior) {
    
    vol_desc <- case_when(
      volatility_metrics$volatility_level == "very_low" ~ "very stable",
      volatility_metrics$volatility_level == "low" ~ "stable", 
      volatility_metrics$volatility_level == "moderate" ~ "moderately variable",
      volatility_metrics$volatility_level == "high" ~ "volatile",
      volatility_metrics$volatility_level == "very_high" ~ "highly volatile",
      TRUE ~ "unknown variability"
    )
    
    seasonal_desc <- case_when(
      seasonal_metrics$seasonal_level == "very_weak" ~ "very weak",
      seasonal_metrics$seasonal_level == "weak" ~ "weak",
      seasonal_metrics$seasonal_level == "moderate" ~ "moderate", 
      seasonal_metrics$seasonal_level == "strong" ~ "strong",
      seasonal_metrics$seasonal_level == "very_strong" ~ "very strong",
      TRUE ~ "unknown"
    )
    
    reasoning <- paste0(
      "Data is ", vol_desc, " (CV: ", round(volatility_metrics$cv, 2), ") → Changepoint Prior: ", changepoint_prior, ". ",
      "Seasonality is ", seasonal_desc, " (Strength: ", round(seasonal_metrics$strength, 2), ") → Seasonality Prior: ", seasonality_prior, "."
    )
    
    return(reasoning)
  }
  
  # ===== Reactive Updates for Prophet Parameters =====
  
  # Update Prophet parameters when item selection changes (single item mode)
  observeEvent({
    input$forecast_entity
    input$refresh_prophet_params  # Also trigger when refresh button is clicked
  }, {
    # Only proceed if conditions are met
    req(rv$processed_data, input$forecast_entity, input$method == "Prophet", input$auto_optimize_prophet)
    
    # Ensure we have data for the selected item
    entity_data <- rv$processed_data %>% 
      filter(Entity_Name == input$forecast_entity) %>% 
      arrange(Date)
    
    if (nrow(entity_data) == 0) {
      # Update info panel to show no data message
      shinyjs::html("prophet_optimization_info", 
                    paste(icon("exclamation-triangle", style = "color: #ffc107;"),
                          "No data available for selected item."))
      return()
    }
    
    # Show loading state
    shinyjs::html("prophet_optimization_info", 
                  paste(icon("spinner fa-spin", style = "color: #17a2b8;"),
                        "Analyzing data and optimizing parameters..."))
    
    # Calculate optimized parameters (with error handling)
    tryCatch({
      optimized_params <- calculate_prophet_parameters(entity_data)
      
      # Update slider values
      updateSliderInput(session, "changepoint_prior", 
                        value = optimized_params$changepoint_prior)
      updateSliderInput(session, "seasonality_prior", 
                        value = optimized_params$seasonality_prior)
      
      # Update info panel with optimization results
      info_html <- paste0(
        '<div style="display: flex; align-items: flex-start; gap: 10px;">',
        '<i class="fa fa-check-circle" style="color: #28a745; margin-top: 2px;"></i>',
        '<div>',
        '<div style="font-weight: 500; margin-bottom: 5px;">Parameters optimized for ', input$forecast_entity, ':</div>',
        '<div style="font-size: 90%; color: #495057;">',
        optimized_params$reasoning,
        '</div>',
        '</div>',
        '</div>'
      )
      
      shinyjs::html("prophet_optimization_info", info_html)
      
      # Optional: Show detailed metrics in console for debugging
      cat("Prophet optimization for", input$forecast_entity, ":\n")
      cat("  Changepoint Prior:", optimized_params$changepoint_prior, "\n")
      cat("  Seasonality Prior:", optimized_params$seasonality_prior, "\n")
      cat("  CV:", round(optimized_params$volatility_cv, 3), "\n")
      cat("  Seasonal Strength:", round(optimized_params$seasonal_strength, 3), "\n")
      
    }, error = function(e) {
      # Handle optimization errors gracefully
      warning("Prophet parameter optimization failed: ", e$message)
      
      # Reset to defaults
      updateSliderInput(session, "changepoint_prior", value = 0.05)
      updateSliderInput(session, "seasonality_prior", value = 0.5)
      
      # Show error message
      error_html <- paste0(
        '<div style="display: flex; align-items: center; gap: 10px;">',
        '<i class="fa fa-exclamation-triangle" style="color: #dc3545;"></i>',
        '<div style="font-size: 90%; color: #dc3545;">',
        'Optimization failed: ', e$message, '. Using default values.',
        '</div>',
        '</div>'
      )
      
      shinyjs::html("prophet_optimization_info", error_html)
    })
    
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  
  # Handle refresh button clicks specifically  
  observeEvent(input$refresh_prophet_params, {
    if (input$auto_optimize_prophet && input$method == "Prophet") {
      showNotification("Refreshing Prophet parameters...", type = "message", duration = 2)
    }
  }, ignoreInit = TRUE)
  
  # Reset parameters to defaults when auto-optimization is turned off
  observeEvent(input$auto_optimize_prophet, {
    if (!input$auto_optimize_prophet && input$method == "Prophet") {
      # Reset to Prophet defaults when turning off auto-optimization
      updateSliderInput(session, "changepoint_prior", value = 0.05)
      updateSliderInput(session, "seasonality_prior", value = 0.5)
    }
  }, ignoreInit = TRUE)
  
  # Clear Prophet optimization info when switching away from Prophet
  observeEvent(input$method, {
    if (input$method != "Prophet") {
      # Clear the info panel when not using Prophet
      tryCatch({
        shinyjs::html("prophet_optimization_info", "")
      }, error = function(e) {
        # Ignore errors if element doesn't exist yet
      })
    }
  }, ignoreInit = TRUE)
  
  

  
  # ===== Sample Data Loading Handler =====
  observeEvent(input$load_sample_data, {
    withProgress(message = 'Loading sample data...', value = 0, {
      tryCatch({
        # Generate sample data with realistic patterns
        start_date <- Sys.Date() - 180  # 6 months ago
        end_date <- Sys.Date()
        date_seq <- seq.Date(from = start_date, to = end_date, by = 'day')
        
        # Create sample data for 3 items with different patterns
        sample_data <- data.frame()
        
        # Item 1: Electronics with weekly seasonality and growth trend
        item1_data <- data.frame(
          Date = date_seq,
          Entity_ID = "ELEC001",
          Entity_Name = "Electronics Category",
          Volume = round(
            1000 + # Base level
            50 * sin(2 * pi * as.numeric(date_seq - start_date) / 7) + # Weekly seasonality
            2 * as.numeric(date_seq - start_date) + # Growth trend
            rnorm(length(date_seq), 0, 30) # Random noise
          ),
          Marketing_Spend = round(runif(length(date_seq), 500, 2000), 0),
          Temperature = round(20 + 10 * sin(2 * pi * as.numeric(date_seq - start_date) / 365.25) + rnorm(length(date_seq), 0, 3), 1),
          Local_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.9, 0.1)),
          National_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.95, 0.05)),
          International_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.98, 0.02))
        )
        
        # Item 2: Apparel with seasonal pattern and weekend peaks
        item2_data <- data.frame(
          Date = date_seq,
          Entity_ID = "APPR002", 
          Entity_Name = "Apparel Category",
          Volume = round(
            600 + # Base level
            100 * sin(2 * pi * as.numeric(date_seq - start_date) / 365.25) + # Yearly seasonality
            80 * sin(2 * pi * as.numeric(date_seq - start_date) / 7) + # Weekly seasonality
            ifelse(weekdays(date_seq) %in% c("Saturday", "Sunday"), 50, 0) + # Weekend effect
            rnorm(length(date_seq), 0, 25) # Random noise
          ),
          Marketing_Spend = round(runif(length(date_seq), 300, 1500), 0),
          Temperature = round(20 + 10 * sin(2 * pi * as.numeric(date_seq - start_date) / 365.25) + rnorm(length(date_seq), 0, 3), 1),
          Local_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.9, 0.1)),
          National_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.95, 0.05)),
          International_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.98, 0.02))
        )
        
        # Item 3: Food with daily patterns and special events
        item3_data <- data.frame(
          Date = date_seq,
          Entity_ID = "FOOD003",
          Entity_Name = "Food & Beverages",
          Volume = round(
            800 + # Base level
            150 * sin(2 * pi * as.numeric(date_seq - start_date) / 365.25) + # Yearly seasonality
            30 * sin(2 * pi * as.numeric(date_seq - start_date) / 7) + # Weekly seasonality
            ifelse(format(date_seq, "%d") %in% c("01", "15"), 100, 0) + # Monthly peaks
            rnorm(length(date_seq), 0, 40) # Random noise
          ),
          Marketing_Spend = round(runif(length(date_seq), 800, 2500), 0),
          Temperature = round(20 + 10 * sin(2 * pi * as.numeric(date_seq - start_date) / 365.25) + rnorm(length(date_seq), 0, 3), 1),
          Local_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.9, 0.1)),
          National_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.95, 0.05)),
          International_Match = sample(c(0, 1), length(date_seq), replace = TRUE, prob = c(0.98, 0.02))
        )
        
        # Combine all items
        sample_data <- rbind(item1_data, item2_data, item3_data)
        
        
        # Ensure no negative values
        sample_data$Volume <- pmax(sample_data$Volume, 0)
        
        # Data type conversion (same as file upload)
        sample_data <- sample_data %>%
          mutate(
            Date = as.Date(Date),
            Entity_ID = as.character(Entity_ID),
            Entity_Name = as.character(Entity_Name),
            Volume = as.numeric(Volume)
          )
        
        # Store data in reactive values (same pattern as file upload)
        rv$data <- sample_data %>% distinct() %>% arrange(Entity_ID, Date)
        rv$processed_data <- rv$data # Initialize processed data
        rv$data_loaded <- TRUE
        rv$forecast_generated <- FALSE # Reset forecast status
        rv$forecast_results <- NULL
        rv$model_objects <- list()
        rv$performance_metrics <- list()
        rv$preprocessing_steps <- list()
        rv$outliers <- NULL
        
        # Update item selectors (same pattern as file upload)
        item_choices <- sort(unique(sample_data$Entity_Name))
        
        tryCatch({
          updateSelectizeInput(session, "selectentity",
                              choices = item_choices,
                              selected = item_choices[1],
                              server = TRUE)
        }, error = function(e) {warning("Could not update selectentity")})
        
        tryCatch({
          updateSelectizeInput(session, "forecast_entity",
                              choices = item_choices,
                              selected = item_choices[1],
                              server = TRUE)
        }, error = function(e) {warning("Could not update forecast_entity")})
        
        tryCatch({
          updateSelectizeInput(session, "results_entity",
                              choices = item_choices,
                              selected = item_choices[1],
                              server = TRUE)
        }, error = function(e) {warning("Could not update results_entity")})
        
        tryCatch({
          updateSelectizeInput(session, "diagnostics_entity",
                              choices = item_choices,
                              selected = item_choices[1],
                              server = TRUE)
        }, error = function(e) {warning("Could not update diagnostics_entity")})
        
        rv$current_entity <- item_choices[1] # Set current item
        showNotification("Sample data loaded successfully! Ready for analysis and forecasting.", type = "message")
        
      }, error = function(e) {
        rv$error_message <- paste("Error loading sample data:", e$message)
        showNotification(rv$error_message, type = "error", duration = 10)
        rv$data <- NULL
        rv$processed_data <- NULL
        rv$data_loaded <- FALSE
      })
    })
  })
  
  # ===== Template Download Handler =====
  output$download_Tem <- downloadHandler(
    filename = function() {
      "forecast_template.xlsx"
    },
    content = function(file) {
      # Create template data (Same as original)
      date_seq <- data.frame(Date = seq.Date(
        from = Sys.Date() - days(30),
        to = Sys.Date(),
        by = 'day'
      ))
      item_seq <- data.frame(Entity_ID = c(1001, 1002, 1003))
      template_data <- crossing(date_seq, item_seq) %>%
        mutate(
          Entity_Name = case_when(
            Entity_ID == 1001 ~ "Product A",
            Entity_ID == 1002 ~ "Product B",
            Entity_ID == 1003 ~ "Product C",
            TRUE ~ paste0("Item ", Entity_ID)
          ),
          Volume = round(
            case_when(
              Entity_ID == 1001 ~ runif(n(), 800, 1200) + 100 * sin(as.numeric(Date - min(Date)) / 7),
              Entity_ID == 1002 ~ runif(n(), 400, 600) + 50 * cos(as.numeric(Date - min(Date)) / 7),
              Entity_ID == 1003 ~ runif(n(), 1000, 1500) + 200 * sin(as.numeric(Date - min(Date)) / 14),
              TRUE ~ runif(n(), 500, 1000)
            )
          ),
          Marketing_Spend = round(runif(n(), 500, 2000), 0),
          Temperature = round(20 + 5 * sin(2 * pi * as.numeric(Date - min(Date)) / 365.25) + rnorm(n(), 0, 2), 1),
          Local_Match = sample(c(0, 1), n(), replace = TRUE, prob = c(0.9, 0.1)),
          National_Match = sample(c(0, 1), n(), replace = TRUE, prob = c(0.95, 0.05)),
          International_Match = sample(c(0, 1), n(), replace = TRUE, prob = c(0.98, 0.02))
        ) %>%
        select(Date, Entity_ID, Entity_Name, Volume, Marketing_Spend, Temperature, Local_Match, National_Match, International_Match)
      write_xlsx(template_data, file)
    }
  )
  
  # ===== File Upload Handler =====
  observeEvent(input$file, {
    req(input$file)
    withProgress(message = 'Loading data...', value = 0, {
      tryCatch({
        file_ext <- tools::file_ext(input$file$datapath)
        if (file_ext == "csv") {
          data <- tryCatch({
            # Add UTF-8 encoding explicitly
            read.csv(
              input$file$datapath,
              header = TRUE,
              stringsAsFactors = FALSE,
              fileEncoding = "UTF-8-BOM" # Explicitly use UTF-8 with BOM
            )
          }, error = function(e1) {
            tryCatch({
              read.csv(
                input$file$datapath,
                header = TRUE,
                stringsAsFactors = FALSE,
                sep = ";",
                fileEncoding = "UTF-8" # Try regular UTF-8
              )
            }, error = function(e2) {
              # Last resort without encoding specified
              read.csv(
                input$file$datapath,
                header = TRUE,
                stringsAsFactors = FALSE
              )
            })
          })
        } else if (file_ext %in% c("xlsx", "xls")) {
          # For Excel files, add encoding considerations
          data <- tryCatch({
            read_excel(input$file$datapath)
          }, error = function(e) {
            # If standard read fails, try force repair
            read_excel(input$file$datapath, .name_repair = "unique")
          })
        } else {
          stop("Unsupported file format.")
        }
        
        required_cols <- c("Date", "Entity_ID", "Entity_Name", "Volume")
        current_cols_lower <- tolower(colnames(data))
        col_mapping <- sapply(tolower(required_cols), function(req_col) {
          match_idx <- match(req_col, current_cols_lower)
          if (!is.na(match_idx))
            colnames(data)[match_idx]
          else
            NA
        })
        if (any(is.na(col_mapping))) {
          stop(paste(
            "Missing required columns:",
            paste(required_cols[is.na(col_mapping)], collapse = ", ")
          ))
        }
        
        # Identify additional columns (potential regressors)
        mapped_col_names <- unname(col_mapping)
        mapped_col_indices <- match(mapped_col_names, colnames(data))
        additional_cols <- colnames(data)[-mapped_col_indices]
        
        # Store regressor columns for UI (filter out empty values)
        rv$regressor_columns <- additional_cols[additional_cols != ""]
        cat("Setting regressor columns:", paste(rv$regressor_columns, collapse = ", "), "\n")
        
        # Rename required columns and keep additional ones
        data <- data %>% 
          rename_with(~ required_cols, .cols = all_of(unname(col_mapping))) %>%
          mutate(
            Date = case_when(
              !is.na(lubridate::ymd(Date, quiet = TRUE)) ~ lubridate::ymd(Date, quiet = TRUE),
              !is.na(lubridate::mdy(Date, quiet = TRUE)) ~ lubridate::mdy(Date, quiet = TRUE),
              !is.na(lubridate::dmy(Date, quiet = TRUE)) ~ lubridate::dmy(Date, quiet = TRUE),
              !is.na(as.Date(as.character(Date), format = "%Y-%m-%d")) ~ as.Date(as.character(Date), format = "%Y-%m-%d"),
              !is.na(as.Date(as.character(Date), format = "%m/%d/%Y")) ~ as.Date(as.character(Date), format = "%m/%d/%Y"),
              !is.na(as.Date(as.character(Date), format = "%d-%b-%Y")) ~ as.Date(as.character(Date), format = "%d-%b-%Y"),
              suppressWarnings(!is.na(
                as.Date(as.numeric(Date), origin = "1899-12-30")
              )) ~ suppressWarnings(as.Date(as.numeric(Date), origin = "1899-12-30")),
              TRUE ~ as.Date(NA)
            ),
            Entity_ID = as.character(Entity_ID),
            Entity_Name = trimws(as.character(Entity_Name)),
            Volume = suppressWarnings(as.numeric(gsub(
              ",", "", Volume
            )))
          )
        
        if (any(is.na(data$Date))) {
          stop("Could not parse all dates.")
        }
        if (any(is.na(data$Volume))) {
          warning("Some 'Volume' values could not be converted to numbers.")
        }
        if (any(is.na(data$Entity_Name) |
                data$Entity_Name == "")) {
          warning("Some 'Entity_Name' values are missing or empty.")
          data <- data %>% filter(!is.na(Entity_Name) & Entity_Name != "")
        }
        
        rv$data <- data %>% distinct() %>% arrange(Entity_ID, Date)
        rv$processed_data <- rv$data # Initialize processed data
        rv$data_loaded <- TRUE
        rv$forecast_generated <- FALSE # Reset forecast status
        rv$forecast_results <- NULL
        rv$model_objects <- list()
        rv$performance_metrics <- list()
        rv$preprocessing_steps <- list()
        rv$outliers <- NULL
        
        # --- Update item selectors (needed even if other tabs aren't shown) ---
        # --- These inputs might exist on hidden tabs, prevent errors ---
        item_choices <- sort(unique(data$Entity_Name))
        tryCatch({
          updateSelectizeInput(
            session,
            "selectentity", # Exists on Preprocessing Tab
            choices = item_choices,
            selected = item_choices[1],
            server = TRUE
          )}, error = function(e) {warning("Could not update selectentity")})
        tryCatch({
          updateSelectizeInput(
            session,
            "forecast_entity", # Exists on Forecast Tab
            choices = item_choices,
            selected = item_choices[1],
            server = TRUE
          )}, error = function(e) {warning("Could not update forecast_entity")})
        tryCatch({
          updateSelectizeInput(
            session,
            "results_entity", # Exists on Results Tab
            choices = item_choices,
            selected = item_choices[1],
            server = TRUE
          )}, error = function(e) {warning("Could not update results_entity")})
        tryCatch({
          updateSelectizeInput(
            session,
            "diagnostics_entity", # Exists on Diagnostics Tab
            choices = item_choices,
            selected = item_choices[1],
            server = TRUE
          )}, error = function(e) {warning("Could not update diagnostics_entity")})
        # --- End of selector updates ---
        
        rv$current_entity <- item_choices[1] # Set current item based on loaded data
        showNotification("Data loaded successfully", type = "message")
        
      }, error = function(e) {
        rv$error_message <- paste("Error loading file:", e$message)
        showNotification(rv$error_message,
                         type = "error",
                         duration = 10)
        rv$data <- NULL
        rv$processed_data <- NULL
        rv$data_loaded <- FALSE
        # Clear selectors if error occurs
        tryCatch({updateSelectizeInput(session, "selectentity", choices = character(0), selected = character(0))}, error = function(e) {})
        tryCatch({updateSelectizeInput(session, "forecast_entity", choices = character(0), selected = character(0))}, error = function(e) {})
        tryCatch({updateSelectizeInput(session, "results_entity", choices = character(0), selected = character(0))}, error = function(e) {})
        tryCatch({updateSelectizeInput(session, "diagnostics_entity", choices = character(0), selected = character(0))}, error = function(e) {})
        
      }, warning = function(w) {
        showNotification(paste("Warning:", w$message),
                         type = "warning",
                         duration = 7)
      })
    })
  })
  
  # ===== Regressor Enhancement Panel =====
  output$regressor_enhancement_panel <- renderUI({
    cat("renderUI called for regressor_enhancement_panel\n")
    
    # Check if we have regressor columns
    if (is.null(rv$regressor_columns) || length(rv$regressor_columns) == 0) {
      cat("No regressor columns available\n")
      return(NULL) # Don't show anything if no regressors
    }
    
    cat("Creating regressor enhancement panel with columns:", paste(rv$regressor_columns, collapse = ", "), "\n")
    
    # Create the full enhancement panel
    div(style = "background-color: #e8f5e8; border: 1px solid #c3e6c3; border-radius: 4px; padding: 15px; margin-bottom: 15px;",
        h5("📊 Additional Data Enhancement", style = "margin-top: 0; color: #155724;"),
        p("Your data contains additional columns that can improve forecast accuracy:", style = "margin-bottom: 10px; color: #155724;"),
        
        checkboxGroupInput(
          "selected_regressors",
          "Select columns to use as regressors:",
          choices = setNames(rv$regressor_columns, rv$regressor_columns),
          selected = NULL, # None selected by default
          inline = FALSE
        ),
        
        div(style = "margin-top: 10px; font-size: 90%; color: #666;",
            paste("Available columns:", paste(rv$regressor_columns, collapse = ", "))
        ),
        
        div(style = "font-size: 85%; color: #155724; margin-top: 10px;",
            icon("lightbulb"),
            " Tip: Select columns that influence your volume (e.g., marketing spend, weather, events)"
        )
    )
  })
  
  # ===== Data Preview, Summary, Structure, Missing Plot =====
  output$data_preview <- renderDT({
    req(rv$data)
    display_data <- rv$data %>% mutate(Date = format(Date, "%Y-%m-%d")) %>% select(Date, Entity_ID, Entity_Name, Volume)
    datatable(
      display_data,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        autoWidth = TRUE,
        searching = TRUE
      ),
      rownames = FALSE,
      filter = 'top',
      class = 'cell-border stripe compact hover',
      caption = "Preview of uploaded data"
    )
  })
  
  output$data_summary <- renderPrint({
    req(rv$processed_data, rv$current_entity)
    
    # Filter data to show statistics for the current selected item only
    data_to_summarize <- rv$processed_data %>% 
      filter(Entity_Name == rv$current_entity)
    
    if (nrow(data_to_summarize) == 0) {
      cat("===== Current Entity Statistics =====\n")
      cat("No data available for the selected item.\n")
      return()
    }
    
    cat("===== Current Entity Statistics =====\n")
    cat("Item:", rv$current_entity, "\n")
    cat("Total observations:", nrow(data_to_summarize), "\n")
    
    if (nrow(data_to_summarize) > 0) {
      cat("Date range:",
          format(min(data_to_summarize$Date, na.rm = TRUE), "%Y-%m-%d"),
          "to",
          format(max(data_to_summarize$Date, na.rm = TRUE), "%Y-%m-%d"),
          "\n")
      
      cat("Item ID:", unique(data_to_summarize$Entity_ID)[1], "\n\n")
      
      cat("----- Volume Statistics -----\n")
      print(summary(data_to_summarize$Volume))
      
      missing_count <- sum(is.na(data_to_summarize$Volume))
      if (missing_count > 0) {
        cat("\nMissing values in Volume:",
            missing_count,
            "(",
            round(missing_count / nrow(data_to_summarize) * 100, 2),
            "%)\n")
      } else {
        cat("\nNo missing values in Volume\n")
      }
      
      cat("\n----- Observations per Item (Top 10) -----\n")
      item_counts <- data_to_summarize %>%
        count(Entity_Name, sort = TRUE) %>%
        rename(Observations = n)
      
      print(head(item_counts, 10))
    } else {
      cat("No data loaded.\n")
    }
  })
  
  
  output$data_structure <- renderPrint({
    req(rv$data)
    cat("===== Data Structure (str) =====\n")
    str(rv$data)
    cat("\n===== First 6 Rows (head) =====\n")
    print(head(rv$data))
    cat("\n===== Column Classes =====\n")
    print(sapply(rv$data, class))
    
  })
  
  output$missing_values_plot <- renderPlot({
    req(rv$data)
    if (nrow(rv$data) == 0)
      return(NULL)
    # Optional: Check if naniar is installed
    if (!requireNamespace("naniar", quietly = TRUE)) {
      plot(0, type = 'n', axes = FALSE, ann = FALSE)
      text(1, 0, "Install 'naniar' package for missing value plot.")
      return()
    }
    naniar::gg_miss_var(rv$data, show_pct = TRUE) +
      labs(title = "Missing Values per Column", y = "Count Missing") +
      theme_minimal()
  })
  
  # ===== Status Boxes =====
  output$data_status_box <- renderUI({
    val <- if (rv$data_loaded && !is.null(rv$data) && nrow(rv$data) > 0) paste(nrow(rv$data), "Records") else "Upload data"
    sub <- if (rv$data_loaded && !is.null(rv$data) && nrow(rv$data) > 0) "Data Loaded" else "No Data"
    icon_cls <- if (rv$data_loaded && !is.null(rv$data) && nrow(rv$data) > 0) "check-circle" else "upload"
    box_cls <- if (rv$data_loaded && !is.null(rv$data) && nrow(rv$data) > 0) "status-box status-box-green" else "status-box status-box-yellow"
    div(class = box_cls, icon(icon_cls), h4(val), p(sub))
  })
  
  output$items_count_box <- renderUI({
    req(rv$data_loaded, rv$data)
    n_items <- n_distinct(rv$data$Entity_ID)
    div(class = "status-box status-box-blue", icon("tags"), h4(n_items), p("Unique Items"))
  })
  
  output$date_range_box <- renderUI({
    req(rv$data_loaded, rv$data)
    min_date <- min(rv$data$Date, na.rm = TRUE)
    max_date <- max(rv$data$Date, na.rm = TRUE)
    date_diff <- if (is.finite(min_date) && is.finite(max_date)) as.numeric(max_date - min_date) else NA
    val <- if (!is.na(date_diff)) paste(date_diff, "days") else "N/A"
    sub <- if (!is.na(date_diff)) paste(format(min_date, "%b %d, %Y"), "to", format(max_date, "%b %d, %Y")) else "Date range unavailable"
    div(class = "status-box status-box-purple", icon("calendar-alt"), h4(val), p(sub))
  })
  
  output$forecast_status_box <- renderUI({
    # This box reflects forecast status, which isn't generated on this tab,
    # but we keep the logic as it depends on rv$forecast_generated flag
    val <- if (rv$forecast_generated && !is.null(rv$forecast_results) && nrow(rv$forecast_results) > 0) paste("For", n_distinct(rv$forecast_results$Entity_ID), "item(s)") else "Run forecast"
    sub <- if (rv$forecast_generated && !is.null(rv$forecast_results) && nrow(rv$forecast_results) > 0) "Forecast Ready" else "No Forecast"
    icon_cls <- if (rv$forecast_generated && !is.null(rv$forecast_results) && nrow(rv$forecast_results) > 0) "check-circle" else "hourglass-start"
    box_cls <- if (rv$forecast_generated && !is.null(rv$forecast_results) && nrow(rv$forecast_results) > 0) "status-box status-box-green" else "status-box status-box-red"
    div(class = box_cls, icon(icon_cls), h4(val), p(sub))
  })
  
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)
  # --- Server logic for other tabs (Preprocessing, Forecast, etc.)

  
  # Reactive values - Assume this exists and is populated from Data tab logic
  rv <- reactiveValues(
    data = NULL,              # Assume populated by Data tab
    processed_data = NULL,    # Main data used/modified here
    outliers = NULL,
    forecast_results = NULL,
    model_objects = list(),
    performance_metrics = list(),
    error_message = NULL,
    preprocessing_steps = list(), # Tracks steps applied on this tab
    current_entity = NULL,      # Set by item selector on this tab (or synced)
    data_loaded = FALSE,      # Assume set by Data tab
    forecast_generated = FALSE
    # Other rv elements...
  )
  
  # ===== Helper function to detect frequency =====
  # (Needed for seasonality/aggregation previews/application)
  # detect_frequency <- function(dates) {
  #   if (length(dates) < 2) return(list(freq_numeric = 1, freq_unit = "day"))
  #   dates <- sort(unique(dates))
  #   diffs <- diff(dates)
  #   if (length(diffs) == 0) return(list(freq_numeric = 1, freq_unit = "day"))
  #   diff_table <- table(diffs)
  #   modal_diff <- as.numeric(names(diff_table)[which.max(diff_table)])
  #   if (is.na(modal_diff)) modal_diff <- median(as.numeric(diffs))
  #   if (is.na(modal_diff)) return(list(freq_numeric = 1, freq_unit = "day")) # Handle case of single unique diff
  #   
  #   if (modal_diff >= 28 && modal_diff <= 31) {
  #     return(list(freq_numeric = 12, freq_unit = "month"))
  #   } else if (modal_diff >= 7 && modal_diff < 10) {
  #     return(list(freq_numeric = 52, freq_unit = "week"))
  #   } else if (modal_diff >= 85 && modal_diff < 95) {
  #     return(list(freq_numeric = 4, freq_unit = "quarter"))
  #   } else if (modal_diff >= 360 && modal_diff < 370) {
  #     return(list(freq_numeric = 1, freq_unit = "year"))
  #   } else if (modal_diff <= 1.5) {
  #     # Use 365.25 for daily when frequency matters (like ts object),
  #     # but maybe just 1 for general description? Let's stick to forecast library convention
  #     return(list(freq_numeric = 365.25, freq_unit = "day"))
  #   } else {
  #     # Default to daily or perhaps based on modal diff if interpretable
  #     return(list(freq_numeric = round(365.25 / modal_diff), freq_unit = paste(modal_diff,"-day",sep="")))
  #     # Or simply: return(list(freq_numeric = 1, freq_unit = "other"))
  #   }
  # }
  
  detect_frequency <- function(dates) {
    if (length(dates) < 2) return(list(freq_numeric = 1, freq_unit = "day"))
    
    # Ensure dates are Date objects and sorted
    dates <- as.Date(dates)
    dates <- sort(unique(dates))
    
    # Calculate differences between consecutive dates
    diffs <- as.numeric(diff(dates))
    
    # Handle case where all dates are the same
    if (length(diffs) == 0 || all(is.na(diffs))) {
      return(list(freq_numeric = 1, freq_unit = "day"))
    }
    
    # Find most common difference
    diff_table <- table(diffs)
    if (length(diff_table) == 0) {
      modal_diff <- median(diffs, na.rm = TRUE)
    } else {
      modal_diff <- as.numeric(names(diff_table)[which.max(diff_table)])
    }
    
    # Handle NA or zero modal difference
    if (is.na(modal_diff) || modal_diff <= 0) {
      modal_diff <- median(diffs, na.rm = TRUE)
      if (is.na(modal_diff) || modal_diff <= 0) {
        return(list(freq_numeric = 1, freq_unit = "day"))
      }
    }
    
    # Map to common time series frequencies
    if (modal_diff >= 28 && modal_diff <= 31) {
      return(list(freq_numeric = 12, freq_unit = "month"))
    } else if (modal_diff >= 7 && modal_diff < 10) {
      return(list(freq_numeric = 52, freq_unit = "week"))
    } else if (modal_diff >= 85 && modal_diff < 95) {
      return(list(freq_numeric = 4, freq_unit = "quarter"))
    } else if (modal_diff >= 360 && modal_diff < 370) {
      return(list(freq_numeric = 1, freq_unit = "year"))
    } else if (modal_diff <= 1.5) {
      return(list(freq_numeric = 7, freq_unit = "day"))
    } else {
      # For other frequencies, estimate sensibly
      guessed_freq <- round(365.25 / modal_diff)
      unit <- if(guessed_freq > 1) paste(modal_diff,"-day",sep="") else "other"
      return(list(freq_numeric = max(1, guessed_freq), freq_unit = unit))
    }
  }

  
  
  # ===== Helper function to get frequency details =====
  get_current_frequency <- reactive({
    req(rv$processed_data, rv$current_entity)
    # Use tryCatch for safety if rv$current_entity isn't set yet
    entity_data <- tryCatch({
      rv$processed_data %>% filter(Entity_Name == rv$current_entity) %>% arrange(Date)
    }, error = function(e) { NULL })
    
    if (is.null(entity_data) || nrow(entity_data) < 2) {
      return(list(freq_numeric = 1, freq_unit = "day"))
    }
    # Assuming input$auto_frequency exists on Forecast tab, default to TRUE behavior here
    # Or, if it needs to be controlled, add a similar input to Preprocessing tab
    # For now, let's assume auto-detection is desired for previews
    # freq_setting <- input$auto_frequency %||% TRUE # Use TRUE if input doesn't exist
    # freq_input_val <- input$frequency %||% 7 # Default if input doesn't exist
    
    # Simplified for Preprocessing tab: always auto-detect for previews/actions here
    return(detect_frequency(entity_data$Date))
    
    # --- Original logic if inputs existed ---
    # if (freq_setting) {
    #     return(detect_frequency(entity_data$Date))
    # } else {
    #     user_freq_val <- as.numeric(freq_input_val)
    #     freq_details <- case_when(
    #       user_freq_val == 30 ~ list(freq_numeric = 12, freq_unit = "month"),
    #       user_freq_val == 7  ~ list(freq_numeric = 52, freq_unit = "week"),
    #       user_freq_val == 4  ~ list(freq_numeric = 4, freq_unit = "quarter"),
    #       # Distinguish daily freq=1 from yearly freq=1
    #       user_freq_val == 1 && mean(diff(entity_data$Date)) < 5 ~ list(freq_numeric = 365.25, freq_unit = "day"),
    #       user_freq_val == 1 && mean(diff(entity_data$Date)) > 100 ~ list(freq_numeric = 1, freq_unit = "year"),
    #       TRUE ~ list(freq_numeric = 1, freq_unit = "other") # Default/unknown
    #     )
    #     return(freq_details)
    # }
    # --- End original logic ---
  })
  
  
  # ===== Sync item selection across tabs =====
  # Keep this logic as input$selectentity exists here
  observeEvent(input$selectentity, {
    req(input$selectentity)
    
    # Always update rv$current_entity (simplified logic)
    rv$current_entity <- input$selectentity
    
    # Try to update other selectors if they exist (prevent errors if not)
    tryCatch({
      updateSelectizeInput(session, "forecast_entity", selected = rv$current_entity)
    }, error = function(e) {})
    tryCatch({
      updateSelectizeInput(session, "results_entity", selected = rv$current_entity)
    }, error = function(e) {})
    tryCatch({
      updateSelectizeInput(session, "diagnostics_entity", selected = rv$current_entity)
    }, error = function(e) {})
  })
  
  # Observers for other item selectors (keep for safety if rv$current_entity is modified elsewhere)
  observeEvent(input$forecast_entity, {
    req(input$forecast_entity)
    if (!is.null(rv$current_entity) && input$forecast_entity != rv$current_entity) {
      rv$current_entity <- input$forecast_entity
      if (input$selectentity != rv$current_entity) updateSelectizeInput(session, "selectentity", selected = rv$current_entity)
      # Update others...
      tryCatch({
        if (input$results_entity != rv$current_entity)
          updateSelectizeInput(session, "results_entity", selected = rv$current_entity)
      }, error = function(e) {
      })
      tryCatch({
        if (input$diagnostics_entity != rv$current_entity)
          updateSelectizeInput(session, "diagnostics_entity", selected = rv$current_entity)
      }, error = function(e) {
      })
    }
  }, ignoreInit = TRUE, ignoreNULL = TRUE) # Add ignoreNULL
  
  observeEvent(input$results_entity, {
    req(input$results_entity)
    if (!is.null(rv$current_entity) && input$results_entity != rv$current_entity) {
      rv$current_entity <- input$results_entity
      if (input$selectentity != rv$current_entity) updateSelectizeInput(session, "selectentity", selected = rv$current_entity)
      tryCatch({
        if (input$forecast_entity != rv$current_entity)
          updateSelectizeInput(session, "forecast_entity", selected = rv$current_entity)
      }, error = function(e) {
      })
      tryCatch({
        if (input$diagnostics_entity != rv$current_entity)
          updateSelectizeInput(session, "diagnostics_entity", selected = rv$current_entity)
      }, error = function(e) {
      })
    }
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  
  observeEvent(input$diagnostics_entity, {
    req(input$diagnostics_entity)
    if (!is.null(rv$current_entity) && input$diagnostics_entity != rv$current_entity) {
      rv$current_entity <- input$diagnostics_entity
      if (input$selectentity != rv$current_entity) updateSelectizeInput(session, "selectentity", selected = rv$current_entity)
      tryCatch({
        if (input$forecast_entity != rv$current_entity)
          updateSelectizeInput(session, "forecast_entity", selected = rv$current_entity)
      }, error = function(e) {
      })
      tryCatch({
        if (input$results_entity != rv$current_entity)
          updateSelectizeInput(session, "results_entity", selected = rv$current_entity)
      }, error = function(e) {
      })
    }
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  
  
  # ===== Preprocessing Plot =====
  output$preprocessing_plot <- renderPlotly({
    req(rv$processed_data)
    # Ensure current item is selected if not showing all
    if (!input$show_all_items) {
      req(rv$current_entity)
    }
    
    if (input$show_all_items) {
      plot_data <- rv$processed_data
      if(nrow(plot_data) == 0) return(plot_ly() %>% layout(title = "No data available"))
      title_text <- "All Items"
      # Use ggplot for facets if many items
      p_gg <- ggplot(plot_data, aes(x = Date, y = Volume, color = Entity_Name)) +
        geom_line(alpha = 0.7) +
        labs(title = title_text, x = "Date", y = "Volume") +
        theme_minimal() +
        theme(legend.position = "none")
      
      num_entities <- n_distinct(plot_data$Entity_Name)
      if (num_entities > 1 && num_entities <= 10) {
        p_gg <- p_gg + facet_wrap(~Entity_Name, scales = "free_y", ncol = 2) + theme(legend.position = "bottom")
      } else if (num_entities > 10) {
        p_gg <- p_gg + facet_wrap(~Entity_Name, scales = "free_y") # Default layout for many items
      }
      # Add outlier highlighting if applicable
      if (input$show_outliers && !is.null(rv$outliers) && nrow(rv$outliers) > 0) {
        outlier_data_all <- rv$outliers # Already filtered by detection step if applied
        if(nrow(outlier_data_all) > 0) {
          p_gg <- p_gg + geom_point(data = outlier_data_all, aes(x=Date, y=Volume), color = '#dd4b39', size = 2, shape = 1) # Circle shape
        }
      }
      
      ggplotly(p_gg, tooltip = c("Date", "Volume", "Entity_Name")) %>%
        layout(title = list(text = paste("Time Series Visualization:", title_text)))
      
    } else {
      # Plot for single selected item
      plot_data <- rv$processed_data %>% filter(Entity_Name == rv$current_entity) %>% arrange(Date)
      if (nrow(plot_data) == 0) return(plot_ly() %>% layout(title = paste("No data for:", rv$current_entity)))
      
      title_text <- rv$current_entity
      p <- plot_ly(data = plot_data, x = ~Date, y = ~Volume, name = 'Volume', hoverinfo = 'x+y+name')
      
      # Apply selected plot type
      if (input$plot_type == "Line") {
        p <- p %>% add_trace(type = 'scatter', mode = 'lines', line = list(color = '#00a65a', width = 2))
      } else if (input$plot_type == "Bar") {
        p <- p %>% add_trace(type = 'bar', marker = list(color = '#00a65a'))
      } else if (input$plot_type == "Point") {
        p <- p %>% add_trace(type = 'scatter', mode = 'markers', marker = list(color = '#00a65a', size = 5))
      } else if (input$plot_type == "Area") {
        p <- p %>% add_trace(
          type = 'scatter',
          mode = 'lines',
          fill = 'tozeroy',
          fillcolor = 'rgba(0, 166, 90, 0.4)',
          line = list(color = '#00a65a', width = 2)
        )
      }
      
      # Add outliers if requested and available for the current item
      if (input$show_outliers && !is.null(rv$outliers) && nrow(rv$outliers) > 0) {
        outlier_data_item <- rv$outliers %>% filter(Entity_Name == rv$current_entity)
        if (nrow(outlier_data_item) > 0) {
          p <- p %>% add_trace(
            data = outlier_data_item, x = ~Date, y = ~Volume,
            type = 'scatter', mode = 'markers',
            marker = list(color = '#dd4b39', size = 8, symbol = 'circle-open'),
            name = 'Outlier', hoverinfo = 'x+y+name'
          )
        }
      }
      
      p %>% layout(
        title = list(text = paste("Time Series Visualization:", title_text)),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Volume"),
        hovermode = "closest",
        showlegend = TRUE # Show legend for 'Volume' and 'Outlier'
      )
    }
  })
  
  # ===== Detect Outliers Function =====
  # Uses IQR method as per the UI default
  detect_outliers_iqr <- function(data, threshold = 1.5) {
    if (!"Volume" %in% names(data) || nrow(data) < 5) {
      return(data %>% mutate(is_outlier = FALSE)) # Return original data with flag
    }
    # Group by item to calculate IQR per item
    data %>% group_by(Entity_ID) %>%
      mutate(
        Q1 = quantile(Volume, 0.25, na.rm = TRUE),
        Q3 = quantile(Volume, 0.75, na.rm = TRUE),
        IQR_val = Q3 - Q1, # Renamed to avoid conflict with IQR function
        lower_bound = Q1 - threshold * IQR_val,
        upper_bound = Q3 + threshold * IQR_val,
        # Mark as outlier if outside bounds, but only if IQR is not zero (constant data)
        is_outlier = ifelse(IQR_val > 0, Volume < lower_bound | Volume > upper_bound, FALSE),
        is_outlier = ifelse(is.na(is_outlier), FALSE, is_outlier) # Handle NAs generated by quantile if too few points
      ) %>%
      # Don't select out columns here, keep them temporarily if needed, remove later
      ungroup() # Ungroup after mutation
  }
  
  # ===== Handle Missing Values =====
  observeEvent(input$apply_missing, {
    req(rv$processed_data)
    method <- input$missing_treatment
    showNotification(paste("Applying missing value treatment:", method), type="message", duration=2)
    
    withProgress(message = paste('Handling missing values using', method, '...'), value = 0.1, {
      tryCatch({
        original_rows <- nrow(rv$processed_data)
        start_time <- Sys.time()
        
        # Group by Entity_ID to apply imputation per item
        processed_data_grouped <- rv$processed_data %>%
          group_by(Entity_ID) %>%
          arrange(Date) # IMPORTANT: Ensure data is sorted by date within each group
        
        # Apply imputation
        if (method == "remove") {
          processed_data_imputed <- processed_data_grouped %>% filter(!is.na(Volume))
        } else if (method == "linear") {
          processed_data_imputed <- processed_data_grouped %>%
            mutate(Volume = if(sum(!is.na(Volume)) >= 2) zoo::na.approx(Volume, na.rm = FALSE, rule = 2) else Volume)
        } else if (method == "ffill") {
          processed_data_imputed <- processed_data_grouped %>% tidyr::fill(Volume, .direction = "down")
        } else if (method == "bfill") {
          processed_data_imputed <- processed_data_grouped %>% tidyr::fill(Volume, .direction = "up")
        } else if (method == "mean") {
          processed_data_imputed <- processed_data_grouped %>%
            mutate(Volume = ifelse(is.na(Volume), mean(Volume, na.rm = TRUE), Volume))
        } else if (method == "median") {
          processed_data_imputed <- processed_data_grouped %>%
            mutate(Volume = ifelse(is.na(Volume), median(Volume, na.rm = TRUE), Volume))
        } else {
          processed_data_imputed <- processed_data_grouped # Should not happen
        }
        
        # Handle potential NaNs introduced by mean/median on all-NA groups
        processed_data_final <- processed_data_imputed %>%
          mutate(Volume = ifelse(is.nan(Volume), NA, Volume)) %>%
          ungroup() # Ungroup after processing
        
        incProgress(0.8)
        
        end_time <- Sys.time()
        rows_after <- nrow(processed_data_final)
        rows_removed <- if (method == "remove") original_rows - rows_after else 0
        
        # Log the step
        step_id <- paste0("missing_", format(Sys.time(), "%Y%m%d%H%M%S"))
        rv$preprocessing_steps[[step_id]] <- list(
          step = "Missing Values",
          method = method,
          rows_removed = rows_removed,
          timestamp = Sys.time()
        )
        
        # Update the reactive value
        rv$processed_data <- processed_data_final
        duration <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)
        msg <- paste("Missing values handled via", method, "in", duration, "sec.")
        if (rows_removed > 0) msg <- paste(msg, rows_removed, "rows removed.")
        showNotification(msg, type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error handling missing values:", e$message), type = "error", duration = 10)
      })
    })
  })
  
  # ===== Handle Duplicates =====
  observeEvent(input$apply_duplicates, {
    req(rv$processed_data)
    method <- input$duplicate_handling
    showNotification(paste("Applying duplicate handling:", method), type="message", duration=2)
    
    # Skip if method is 'keep'
    if (method == "keep") {
      showNotification("Keeping all rows (no changes made for duplicates).", type = "message")
      # Optionally log this 'no-op' step
      step_id <- paste0("duplicates_", format(Sys.time(), "%Y%m%d%H%M%S"))
      rv$preprocessing_steps[[step_id]] <- list(
        step = "Duplicates", method = method, rows_removed = 0, timestamp = Sys.time()
      )
      return()
    }
    
    withProgress(message = paste('Handling duplicates using', method, '...'), value = 0.1, {
      tryCatch({
        original_rows <- nrow(rv$processed_data)
        start_time <- Sys.time()
        
        # Identify duplicates based on Entity_ID and Date
        duplicates_info <- rv$processed_data %>%
          group_by(Entity_ID, Date) %>%
          summarise(count = n(), .groups = "drop") %>%
          filter(count > 1)
        
        processed_data_dedup <- rv$processed_data # Start with original
        
        if (nrow(duplicates_info) == 0 && method != "keep") {
          showNotification("No duplicate Date/Entity_ID combinations found.", type = "message")
          # Still log the step if method wasn't 'keep'
          step_id <- paste0("duplicates_", format(Sys.time(), "%Y%m%d%H%M%S"))
          rv$preprocessing_steps[[step_id]] <- list(
            step = "Duplicates", method = method, rows_removed = 0, timestamp = Sys.time()
          )
          return() # Exit progress bar
        }
        
        incProgress(0.3)
        
        # Apply selected method
        if (method == "first") {
          # Keep the first occurrence based on original row order (requires stable sort or row numbers)
          # A safer way using arrange before slicing:
          processed_data_dedup <- rv$processed_data %>%
            # Add a row number if needed: mutate(original_row = row_number()) %>%
            arrange(Entity_ID, Date) %>% # Sort to ensure consistency if order matters
            group_by(Entity_ID, Date) %>%
            slice(1) %>% # Keep the first row within each group
            ungroup()
        } else if (method == "last") {
          processed_data_dedup <- rv$processed_data %>%
            # Add a row number if needed: mutate(original_row = row_number()) %>%
            arrange(Entity_ID, Date) %>% # Sort first
            group_by(Entity_ID, Date) %>%
            slice(n()) %>% # Keep the last row within each group
            ungroup()
        } else if (method == "sum") {
          # Aggregate Volume by sum, keeping Entity_Name from the first occurrence
          processed_data_dedup <- rv$processed_data %>%
            group_by(Entity_ID, Date) %>%
            summarise(
              Entity_Name = first(Entity_Name), # Keep one name
              Volume = sum(Volume, na.rm = TRUE),
              .groups = "drop"
            ) %>% ungroup() %>% select(Date, Entity_ID, Entity_Name, Volume) # Ensure column order
        } else if (method == "mean") {
          processed_data_dedup <- rv$processed_data %>%
            group_by(Entity_ID, Date) %>%
            summarise(
              Entity_Name = first(Entity_Name),
              Volume = mean(Volume, na.rm = TRUE),
              .groups = "drop"
            ) %>% ungroup() %>% select(Date, Entity_ID, Entity_Name, Volume)
        }
        # 'keep' case handled earlier
        
        incProgress(0.8)
        end_time <- Sys.time()
        rows_after <- nrow(processed_data_dedup)
        rows_removed <- original_rows - rows_after
        
        # Log the step
        step_id <- paste0("duplicates_", format(Sys.time(), "%Y%m%d%H%M%S"))
        rv$preprocessing_steps[[step_id]] <- list(
          step = "Duplicates", method = method, rows_removed = rows_removed, timestamp = Sys.time()
        )
        
        # Update reactive value
        rv$processed_data <- processed_data_dedup
        duration <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)
        showNotification(paste("Duplicates handled via", method, "in", duration, "sec.", rows_removed, "rows removed/aggregated."), type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error handling duplicates:", e$message), type = "error", duration = 10)
      })
    })
  })
  
  # ===== Handle Outliers =====
  observeEvent(input$apply_outliers, {
    req(rv$processed_data)
    detection_method <- input$outlier_method # Currently only IQR is implemented in helper
    action <- input$outlier_action
    threshold <- input$outlier_threshold
    showNotification(paste("Applying outlier handling:", action), type="message", duration=2)
    
    withProgress(message = paste('Detecting outliers using', detection_method, '...'), value = 0.1, {
      tryCatch({
        start_time <- Sys.time()
        
        # 1. Detect Outliers (using the chosen method - currently only IQR)
        #    We always detect first to update rv$outliers for visualization
        if (detection_method == "iqr") {
          # The function adds the 'is_outlier' column
          data_with_outliers <- detect_outliers_iqr(rv$processed_data, threshold = threshold)
        } else if (detection_method == "zscore") {
          # Implement Z-score detection (example)
          data_with_outliers <- rv$processed_data %>%
            group_by(Entity_ID) %>%
            mutate(
              mean_vol = mean(Volume, na.rm = TRUE),
              sd_vol = sd(Volume, na.rm = TRUE),
              z_score = ifelse(sd_vol > 0, (Volume - mean_vol) / sd_vol, 0),
              is_outlier = ifelse(is.na(z_score), FALSE, abs(z_score) > threshold)
            ) %>%
            ungroup() # Keep mean/sd/zscore temporarily if needed, select out later
          # GESD needs a dedicated package/function (e.g., from EnvStats or anomalies)
        } else if (detection_method == "gesd") {
          showNotification("GESD outlier detection not yet implemented in this server snippet.", type="warning")
          return() # Stop processing for GESD
        } else {
          showNotification("Unknown outlier detection method.", type="error")
          return()
        }
        
        incProgress(0.4, message = "Detecting outliers...")
        
        # Store detected outliers regardless of action (for highlighting)
        # Select necessary columns for storage
        rv$outliers <- data_with_outliers %>%
          filter(is_outlier) %>%
          select(Date, Entity_ID, Entity_Name, Volume) # Store only essential info + original Volume
        
        n_outliers <- nrow(rv$outliers)
        
        # 2. Apply Action (if not 'keep')
        processed_data_handled <- data_with_outliers # Start with data including the is_outlier flag
        
        if (action == "keep") {
          showNotification(paste(n_outliers, "outliers detected (kept)."), type = "message")
          # Remove temporary columns before finishing
          processed_data_handled <- processed_data_handled %>% select(-any_of(
            c(
              "Q1",
              "Q3",
              "IQR_val",
              "lower_bound",
              "upper_bound",
              "mean_vol",
              "sd_vol",
              "z_score",
              "is_outlier"
            )
          ))
        } else {
          # Only proceed with actions if outliers were found
          if (n_outliers == 0) {
            showNotification("No outliers detected to apply action.", type = "message")
            processed_data_handled <- processed_data_handled %>% select(-any_of(
              c(
                "Q1",
                "Q3",
                "IQR_val",
                "lower_bound",
                "upper_bound",
                "mean_vol",
                "sd_vol",
                "z_score",
                "is_outlier"
              )
            ))
          } else {
            setProgress(0.6, message = paste('Applying action:', action, '...'))
            
            # Apply action per group
            processed_data_handled <- processed_data_handled %>% group_by(Entity_ID)
            
            if (action == "remove") {
              processed_data_handled <- processed_data_handled %>% filter(!is_outlier)
            } else if (action == "mean") {
              processed_data_handled <- processed_data_handled %>%
                mutate(
                  replace_val = mean(Volume[!is_outlier], na.rm = TRUE), # Calculate mean of non-outliers
                  Volume = ifelse(is_outlier, replace_val, Volume)
                )
            } else if (action == "median") {
              processed_data_handled <- processed_data_handled %>%
                mutate(
                  replace_val = median(Volume[!is_outlier], na.rm = TRUE), # Median of non-outliers
                  Volume = ifelse(is_outlier, replace_val, Volume)
                )
            } else if (action == "winsorize") {
              # Winsorize at 5th/95th percentile of non-outliers
              processed_data_handled <- processed_data_handled %>%
                mutate(
                  # Calculate percentiles based on non-outliers within the group
                  p05 = quantile(Volume[!is_outlier], 0.05, na.rm = TRUE),
                  p95 = quantile(Volume[!is_outlier], 0.95, na.rm = TRUE),
                  # Apply capping using calculated percentiles
                  Volume = case_when(
                    is_outlier & Volume < p05 ~ p05,
                    is_outlier & Volume > p95 ~ p95,
                    TRUE ~ Volume # Keep original value if not an outlier or within bounds
                  )
                )
            }
            # Ungroup and remove temporary columns
            processed_data_handled <- processed_data_handled %>%
              ungroup() %>%
              select(-any_of(
                c(
                  "Q1",
                  "Q3",
                  "IQR_val",
                  "lower_bound",
                  "upper_bound",
                  "mean_vol",
                  "sd_vol",
                  "z_score",
                  "replace_val",
                  "p05",
                  "p95",
                  "is_outlier"
                )
              ))
          }
        }
        
        incProgress(0.9)
        end_time <- Sys.time()
        rows_after <- nrow(processed_data_handled)
        rows_removed <- if (action == "remove") n_outliers else 0
        
        # Log the step
        step_id <- paste0("outliers_", format(Sys.time(), "%Y%m%d%H%M%S"))
        rv$preprocessing_steps[[step_id]] <- list(
          step = "Outliers",
          detection_method = detection_method,
          threshold = threshold,
          action = action,
          outliers_found = n_outliers,
          rows_removed = rows_removed,
          timestamp = Sys.time()
        )
        
        # Update reactive value
        rv$processed_data <- processed_data_handled
        
        duration <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)
        msg <- paste(n_outliers, "outliers identified via", detection_method, ".")
        if (action != "keep" && n_outliers > 0) {
          msg <- paste(msg, "Action '", action, "' applied in", duration, "sec.")
          if (rows_removed > 0) msg <- paste(msg, rows_removed, "rows removed.")
        } else if (action != "keep" && n_outliers == 0) {
          msg <- paste(msg, "No action applied.")
        } else { # action == "keep"
          msg <- paste(msg, "Outliers kept.")
        }
        showNotification(msg, type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error handling outliers:", e$message), type = "error", duration = 10)
      })
    })
  })
  
  
# ===== Enhanced Value Replacement Preview =====
output$value_replacement_preview <- renderUI({
  req(rv$processed_data, rv$current_entity)
  
  # Get current item data
  entity_data <- rv$processed_data %>% filter(Entity_Name == rv$current_entity)
  if(nrow(entity_data) == 0) {
    return(div(class = "alert alert-warning", 
               icon("exclamation-triangle"), 
               "No data available for selected item."))
  }
  
  # Get condition parameters
  condition <- input$value_condition
  threshold1 <- input$value_threshold1
  threshold2 <- input$value_threshold2
  replacement_method <- input$replacement_method
  replacement_value <- input$replacement_value
  
  # Calculate affected records
  affected_count <- 0
  condition_text <- ""
  replacement_text <- ""
  
  if(!is.null(condition) && !is.na(threshold1)) {
    # Determine condition
    if(condition == "less_than") {
      affected_count <- sum(entity_data$Volume < threshold1, na.rm = TRUE)
      condition_text <- paste("Values less than", threshold1)
    } else if(condition == "greater_than") {
      affected_count <- sum(entity_data$Volume > threshold1, na.rm = TRUE)
      condition_text <- paste("Values greater than", threshold1)
    } else if(condition == "equal_to") {
      affected_count <- sum(entity_data$Volume == threshold1, na.rm = TRUE)
      condition_text <- paste("Values equal to", threshold1)
    } else if(condition == "between" && !is.na(threshold2)) {
      min_val <- min(threshold1, threshold2)
      max_val <- max(threshold1, threshold2)
      affected_count <- sum(entity_data$Volume >= min_val & entity_data$Volume <= max_val, na.rm = TRUE)
      condition_text <- paste("Values between", min_val, "and", max_val)
    }
    
    # Determine replacement text and validate
    if(!is.null(replacement_method)) {
      if(replacement_method == "specific_value") {
        replacement_text <- paste("with", replacement_value)
      } else if(replacement_method == "weekday_mean") {
        replacement_text <- "with mean of same weekday"
        
        # Check if we have enough data for weekday calculations
        if(affected_count > 0) {
          entity_data_with_weekday <- entity_data %>%
            mutate(weekday = weekdays(Date))
          
          weekday_counts <- entity_data_with_weekday %>%
            group_by(weekday) %>%
            summarise(count = sum(!is.na(Volume)), .groups = "drop")
          
          min_weekday_count <- min(weekday_counts$count)
          if(min_weekday_count < 3) {
            replacement_text <- paste(replacement_text, "(Warning: Some weekdays have < 3 observations)")
          }
        }
      } else if(replacement_method == "weekday_median") {
        replacement_text <- "with median of same weekday"
        
        # Check if we have enough data for weekday calculations
        if(affected_count > 0) {
          entity_data_with_weekday <- entity_data %>%
            mutate(weekday = weekdays(Date))
          
          weekday_counts <- entity_data_with_weekday %>%
            group_by(weekday) %>%
            summarise(count = sum(!is.na(Volume)), .groups = "drop")
          
          min_weekday_count <- min(weekday_counts$count)
          if(min_weekday_count < 3) {
            replacement_text <- paste(replacement_text, "(Warning: Some weekdays have < 3 observations)")
          }
        }
      }
    }
  }
  
  # Create preview message with weekday breakdown for weekday methods
  if(affected_count > 0 && replacement_method %in% c("weekday_mean", "weekday_median")) {
    # Calculate weekday breakdown of affected records
    entity_data_filtered <- entity_data
    if(condition == "less_than") {
      entity_data_filtered <- entity_data_filtered %>% filter(Volume < threshold1)
    } else if(condition == "greater_than") {
      entity_data_filtered <- entity_data_filtered %>% filter(Volume > threshold1)
    } else if(condition == "equal_to") {
      entity_data_filtered <- entity_data_filtered %>% filter(Volume == threshold1)
    } else if(condition == "between" && !is.na(threshold2)) {
      min_val <- min(threshold1, threshold2)
      max_val <- max(threshold1, threshold2)
      entity_data_filtered <- entity_data_filtered %>% filter(Volume >= min_val & Volume <= max_val)
    }
    
    if(nrow(entity_data_filtered) > 0) {
      weekday_breakdown <- entity_data_filtered %>%
        mutate(weekday = weekdays(Date)) %>%
        count(weekday, name = "affected_count") %>%
        arrange(desc(affected_count))
      
      breakdown_text <- paste0("Breakdown by weekday: ", 
                               paste(weekday_breakdown$weekday, "(", weekday_breakdown$affected_count, ")", 
                                     collapse = ", "))
      
      alert_class <- "alert alert-warning"
      icon_name <- "exclamation-triangle"
      message <- paste(condition_text, "will replace", affected_count, "records", replacement_text, ".", breakdown_text)
    } else {
      alert_class <- "alert alert-info"
      icon_name <- "info-circle"
      message <- paste("No records match the condition:", condition_text)
    }
  } else if(affected_count > 0) {
    alert_class <- "alert alert-warning"
    icon_name <- "exclamation-triangle"
    message <- paste(condition_text, "will replace", affected_count, "records", replacement_text)
  } else {
    alert_class <- "alert alert-info"
    icon_name <- "info-circle"
    message <- paste("No records match the condition:", condition_text)
  }
  
  div(class = alert_class,
      icon(icon_name),
      message)
})
  
# ===== Enhanced Apply Value Replacement =====
observeEvent(input$apply_value_replacement, {
  req(rv$processed_data)
  condition <- input$value_condition
  threshold1 <- input$value_threshold1
  threshold2 <- input$value_threshold2
  replacement_method <- input$replacement_method
  replacement_value <- input$replacement_value
  
  if(is.null(condition) || is.na(threshold1) || is.null(replacement_method)) {
    showNotification("Please set all required values for replacement.", type = "warning")
    return()
  }
  
  if(replacement_method == "specific_value" && is.na(replacement_value)) {
    showNotification("Please provide a specific replacement value.", type = "warning")
    return()
  }
  
  showNotification(paste("Applying value replacement:", condition, "with", replacement_method), type="message", duration=2)
  
  withProgress(message = paste('Applying value replacement...'), value = 0.1, {
    tryCatch({
      original_rows <- nrow(rv$processed_data)
      start_time <- Sys.time()
      
      # Apply replacement based on condition and method
      processed_data_replaced <- rv$processed_data %>%
        mutate(weekday = weekdays(Date)) %>%  # Add weekday column for calculations
        group_by(Entity_ID, weekday) %>%
        mutate(
          # Calculate weekday-based replacement values (excluding matching values to avoid bias)
          weekday_mean_val = case_when(
            replacement_method == "weekday_mean" ~ {
              # Calculate mean excluding values that match the condition
              non_matching_values <- case_when(
                condition == "less_than" ~ list(Volume[Volume >= threshold1 & !is.na(Volume)]),
                condition == "greater_than" ~ list(Volume[Volume <= threshold1 & !is.na(Volume)]),
                condition == "equal_to" ~ list(Volume[Volume != threshold1 & !is.na(Volume)]),
                condition == "between" & !is.na(threshold2) ~ {
                  min_val <- min(threshold1, threshold2)
                  max_val <- max(threshold1, threshold2)
                  list(Volume[(Volume < min_val | Volume > max_val) & !is.na(Volume)])
                },
                TRUE ~ list(Volume[!is.na(Volume)])
              )
              
              if(length(non_matching_values[[1]]) >= 3) {
                mean(non_matching_values[[1]], na.rm = TRUE)
              } else {
                NA_real_  # Not enough data for reliable mean
              }
            },
            TRUE ~ NA_real_
          ),
          weekday_median_val = case_when(
            replacement_method == "weekday_median" ~ {
              # Calculate median excluding values that match the condition
              non_matching_values <- case_when(
                condition == "less_than" ~ list(Volume[Volume >= threshold1 & !is.na(Volume)]),
                condition == "greater_than" ~ list(Volume[Volume <= threshold1 & !is.na(Volume)]),
                condition == "equal_to" ~ list(Volume[Volume != threshold1 & !is.na(Volume)]),
                condition == "between" & !is.na(threshold2) ~ {
                  min_val <- min(threshold1, threshold2)
                  max_val <- max(threshold1, threshold2)
                  list(Volume[(Volume < min_val | Volume > max_val) & !is.na(Volume)])
                },
                TRUE ~ list(Volume[!is.na(Volume)])
              )
              
              if(length(non_matching_values[[1]]) >= 3) {
                median(non_matching_values[[1]], na.rm = TRUE)
              } else {
                NA_real_  # Not enough data for reliable median
              }
            },
            TRUE ~ NA_real_
          )
        ) %>%
        ungroup() %>%
        mutate(
          # Apply the actual replacement
          Volume = case_when(
            # Check condition first
            condition == "less_than" & Volume < threshold1 ~ {
              case_when(
                replacement_method == "specific_value" ~ replacement_value,
                replacement_method == "weekday_mean" & !is.na(weekday_mean_val) ~ weekday_mean_val,
                replacement_method == "weekday_median" & !is.na(weekday_median_val) ~ weekday_median_val,
                TRUE ~ Volume  # Keep original if replacement calculation failed
              )
            },
            condition == "greater_than" & Volume > threshold1 ~ {
              case_when(
                replacement_method == "specific_value" ~ replacement_value,
                replacement_method == "weekday_mean" & !is.na(weekday_mean_val) ~ weekday_mean_val,
                replacement_method == "weekday_median" & !is.na(weekday_median_val) ~ weekday_median_val,
                TRUE ~ Volume  # Keep original if replacement calculation failed
              )
            },
            condition == "equal_to" & Volume == threshold1 ~ {
              case_when(
                replacement_method == "specific_value" ~ replacement_value,
                replacement_method == "weekday_mean" & !is.na(weekday_mean_val) ~ weekday_mean_val,
                replacement_method == "weekday_median" & !is.na(weekday_median_val) ~ weekday_median_val,
                TRUE ~ Volume  # Keep original if replacement calculation failed
              )
            },
            condition == "between" & !is.na(threshold2) & 
              Volume >= min(threshold1, threshold2) & 
              Volume <= max(threshold1, threshold2) ~ {
              case_when(
                replacement_method == "specific_value" ~ replacement_value,
                replacement_method == "weekday_mean" & !is.na(weekday_mean_val) ~ weekday_mean_val,
                replacement_method == "weekday_median" & !is.na(weekday_median_val) ~ weekday_median_val,
                TRUE ~ Volume  # Keep original if replacement calculation failed
              )
            },
            TRUE ~ Volume  # Keep original value if no condition matches
          )
        ) %>%
        select(-weekday, -weekday_mean_val, -weekday_median_val)  # Remove temporary columns
      
      incProgress(0.8)
      
      # Count affected records and failed replacements
      original_values <- rv$processed_data$Volume
      new_values <- processed_data_replaced$Volume
      affected_count <- sum(original_values != new_values, na.rm = TRUE)
      
      # Count any failed weekday replacements (where we couldn't calculate mean/median)
      failed_replacements <- 0
      if(replacement_method %in% c("weekday_mean", "weekday_median")) {
        # This is a simplified check - in practice, failed replacements would keep original values
        # We could add more sophisticated tracking if needed
      }
      
      end_time <- Sys.time()
      
      # Log the step with enhanced details
      step_id <- paste0("value_replacement_", format(Sys.time(), "%Y%m%d%H%M%S"))
      
      condition_description <- case_when(
        condition == "less_than" ~ paste("< ", threshold1),
        condition == "greater_than" ~ paste("> ", threshold1),
        condition == "equal_to" ~ paste("= ", threshold1),
        condition == "between" ~ paste("between", min(threshold1, threshold2), "and", max(threshold1, threshold2)),
        TRUE ~ condition
      )
      
      replacement_description <- case_when(
        replacement_method == "specific_value" ~ paste("specific value:", replacement_value),
        replacement_method == "weekday_mean" ~ "mean of same weekday",
        replacement_method == "weekday_median" ~ "median of same weekday",
        TRUE ~ replacement_method
      )
      
      rv$preprocessing_steps[[step_id]] <- list(
        step = "Value Replacement",
        condition = condition_description,
        replacement_method = replacement_description,
        affected_count = affected_count,
        failed_replacements = failed_replacements,
        timestamp = Sys.time()
      )
      
      # Update the reactive value
      rv$processed_data <- processed_data_replaced
      duration <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)
      
      if(affected_count > 0) {
        success_message <- paste("Value replacement completed:", affected_count, "values replaced using", replacement_description, "in", duration, "sec.")
        if(failed_replacements > 0) {
          success_message <- paste(success_message, "Note:", failed_replacements, "replacements failed due to insufficient weekday data.")
        }
        showNotification(success_message, type = "message")
      } else {
        showNotification("No values matched the specified condition.", type = "info")
      }
      
    }, error = function(e) {
      showNotification(paste("Error applying value replacement:", e$message), type = "error", duration = 10)
    })
  })
})
  
  
  # ===== Transformation & Seasonality Preview =====
  # output$transformation_preview <- renderPlotly({
  #   req(rv$processed_data, rv$current_entity)
  #   
  #   entity_data <- rv$processed_data %>% filter(Entity_Name == enc2utf8(rv$current_entity)) %>% arrange(Date)
  #   if (nrow(entity_data) < 5) return(plot_ly() %>% layout(title = "Not enough data for preview"))
  #   
  #   # Decide which preview to show based on selected inputs in the active tab
  #   # Note: input$preprocessing_tabs might be needed if plots are complex and slow,
  #   # but for now, check methods directly.
  #   
  #   transform_method <- input$transform_method
  #   seasonality_method <- input$seasonality_method
  #   adjust_seasonality_flag <- input$adjust_seasonality
  #   
  #   # --- Transformation Preview Logic ---
  #   if (transform_method != "none") {
  #     lambda <- input$lambda # Needed for Box-Cox
  #     
  #     tryCatch({
  #       transformed_volume <- case_when(
  #         transform_method == "log"    ~ log(pmax(entity_data$Volume, 1e-6)), # Avoid log(0)
  #         transform_method == "sqrt"   ~ sqrt(pmax(entity_data$Volume, 0)),    # Avoid sqrt(<0)
  #         transform_method == "boxcox" ~ {
  #           min_vol <- min(entity_data$Volume, na.rm = TRUE)
  #           offset <- if (!is.na(min_vol) && min_vol <= 0) abs(min_vol) + 1e-6 else 0
  #           if (length(unique(entity_data$Volume[entity_data$Volume > 0])) < 2) {
  #             rep(NA_real_, nrow(entity_data)) # Cannot fit BoxCox
  #           } else {
  #             # Ensure lambda is valid
  #             current_lambda <- if(is.na(lambda) || !is.numeric(lambda)) "auto" else lambda
  #             forecast::BoxCox(entity_data$Volume + offset, lambda = current_lambda)
  #           }
  #         },
  #         transform_method == "zscore" ~ as.numeric(scale(entity_data$Volume)),
  #         transform_method == "minmax" ~ {
  #           min_v <- min(entity_data$Volume, na.rm = TRUE)
  #           max_v <- max(entity_data$Volume, na.rm = TRUE)
  #           if (is.na(min_v) || is.na(max_v) || max_v == min_v) {
  #             rep(0.5, nrow(entity_data)) # Or NA, depending on desired behavior
  #           } else {
  #             (entity_data$Volume - min_v) / (max_v - min_v)
  #           }
  #         },
  #         TRUE ~ entity_data$Volume # Should not happen if method != "none"
  #       )
  #       
  #       if(all(is.na(transformed_volume))) {
  #         return(plot_ly() %>% layout(title = paste("Transformation failed for:", transform_method)))
  #       }
  #       
  #       # Create plot with two y-axes
  #       ay <- list(overlaying = "y", side = "right", title = "Transformed", showgrid = FALSE, zeroline = FALSE)
  #       
  #       plot_ly() %>%
  #         add_trace(x = ~entity_data$Date, y = ~entity_data$Volume, type = 'scatter', mode = 'lines',
  #                   line = list(color = '#3c8dbc'), name = 'Original', yaxis = "y1") %>%
  #         add_trace(x = ~entity_data$Date, y = ~transformed_volume, type = 'scatter', mode = 'lines',
  #                   line = list(color = '#00a65a'), name = 'Transformed', yaxis = "y2") %>%
  #         layout(
  #           title = paste("Transformation Preview:", rv$current_entity, "-", transform_method),
  #           xaxis = list(title = "Date"),
  #           yaxis = list(title = "Original"),
  #           yaxis2 = ay,
  #           hovermode = "x unified",
  #           showlegend = TRUE,
  #           legend = list(x = 0.1, y = 0.9)
  #         )
  #       
  #     }, error = function(e) {
  #       plot_ly() %>% layout(title = paste("Error in transformation preview:", e$message))
  #     })
  #     
  #     # --- Seasonality Preview Logic ---
  #   } else if (seasonality_method != "none") {
  #     freq_details <- get_current_frequency()
  #     ts_freq <- freq_details$freq_numeric
  #     
  #     if (ts_freq <= 1) return(plot_ly() %>% layout(title = "Seasonality preview requires frequency > 1"))
  #     
  #     # Ensure enough data for the chosen method
  #     min_periods <- 2
  #     min_data_points <- min_periods * ts_freq
  #     if(seasonality_method == "stl") min_data_points <- min_data_points + 1
  #     
  #     if (nrow(entity_data) < min_data_points) {
  #       return(plot_ly() %>% layout(title = paste("Need at least", min_data_points, "data points for", seasonality_method)))
  #     }
  #     
  #     # Create time series object, handling potential NAs
  #     ts_data <- ts(entity_data$Volume, frequency = ts_freq)
  #     
  #     # Check for too many NAs before decomposition
  #     if (sum(is.na(ts_data)) / length(ts_data) > 0.5) {
  #       return(plot_ly() %>% layout(title = "Too many missing values for decomposition"))
  #     }
  #     
  #     tryCatch({
  #       decomp_df <- NULL
  #       decomp_title <- ""
  #       
  #       if (seasonality_method == "stl") {
  #         # STL needs non-NA series or specific handling
  #         ts_data_imputed <- na.omit(ts_data) # Simple omit for preview, might need interpolation
  #         if(length(ts_data_imputed) < min_data_points) return(plot_ly() %>% layout(title = "Not enough non-NA data for STL"))
  #         
  #         decomp <- stl(ts_data_imputed, s.window = "periodic")
  #         decomp_df <- tryCatch(fortify(decomp), error = function(e) NULL) # Use fortify for ggplot later
  #         decomp_title <- "STL Decomposition Preview"
  #         
  #       } else if (seasonality_method == "decompose") {
  #         ts_data_imputed <- na.omit(ts_data) # Decompose also needs non-NA
  #         if(length(ts_data_imputed) < 2*ts_freq) return(plot_ly() %>% layout(title = "Not enough non-NA data for decompose"))
  #         
  #         decomp_type <- if (input$seasonal_type == "Multiplicative") "multiplicative" else "additive"
  #         decomp <- decompose(ts_data_imputed, type = decomp_type)
  #         # Reconstruct data frame manually or use fortify if available for decompose objects
  #         decomp_df <- data.frame(
  #           Index = time(ts_data_imputed), # Or seq_along if time doesn't work well
  #           Data = as.numeric(decomp$x),
  #           seasonal = as.numeric(decomp$seasonal),
  #           trend = as.numeric(decomp$trend),
  #           remainder = as.numeric(decomp$random)
  #         )
  #         # Assign appropriate .rownames for facetting
  #         decomp_df <- decomp_df %>%
  #           pivot_longer(cols = c(Data, seasonal, trend, remainder), names_to = ".rownames", values_to = "value")
  #         decomp_title <- paste(tools::toTitleCase(decomp_type), "Decomposition Preview")
  #         
  #       } else if (seasonality_method == "ma") {
  #         # Moving average decomposition preview (manual)
  #         ma_order <- floor(ts_freq / 2) * 2 + 1 # Often odd order centered MA
  #         ma_order <- max(3, min(ma_order, length(ts_data) - 2)) # Ensure valid order
  #         
  #         trend_comp <- stats::filter(ts_data, filter = rep(1 / ma_order, ma_order), sides = 2)
  #         # Need to handle NA ends carefully
  #         dates_with_trend <- entity_data$Date[!is.na(trend_comp)]
  #         trend_comp_num <- as.numeric(na.omit(trend_comp))
  #         
  #         # Calculate seasonal component based on original data and trend
  #         # Need to align lengths, might require interpolation or careful indexing
  #         # For preview, maybe just plot trend vs original?
  #         decomp_df <- data.frame(Date=entity_data$Date, Data=entity_data$Volume)
  #         trend_df <- data.frame(Date=dates_with_trend, trend=trend_comp_num)
  #         decomp_df <- left_join(decomp_df, trend_df, by="Date")
  #         
  #         # Simple plot: Original vs Trend
  #         p <- plot_ly() %>%
  #           add_trace(data=decomp_df, x=~Date, y=~Data, type='scatter', mode='lines', name='Original', line=list(color='grey')) %>%
  #           add_trace(data=decomp_df, x=~Date, y=~trend, type='scatter', mode='lines', name='Trend (MA)', line=list(color='#00a65a')) %>%
  #           layout(title = paste("Moving Average Trend Preview:", rv$current_entity), hovermode='x unified')
  #         return(p) # Return MA plot directly
  #         
  #       }
  #       
  #       # Plotting for STL/Decompose using ggplot then plotly
  #       if (!is.null(decomp_df) && nrow(decomp_df) > 0) {
  #         # Use Index if Date isn't properly mapped by fortify
  #         date_mapping <- tryCatch(as.Date(time(decomp$x)), error = function(e) NULL) # Get original dates if possible
  #         if(is.null(date_mapping) || length(date_mapping) != length(unique(decomp_df$Index))) {
  #           # Fallback to numeric index if dates are problematic
  #           p_gg <- ggplot(decomp_df, aes(x = Index, y = value)) +
  #             geom_line(aes(color = .rownames)) + # Color by component
  #             facet_grid(vars(.rownames), scales = "free_y", switch = "y") +
  #             labs(title = paste(decomp_title, ":", rv$current_entity), x = "Time Index", y = "") +
  #             theme_minimal() +
  #             theme(strip.placement = "outside", legend.position = "none", strip.text.y.left = element_text(angle = 0)) +
  #             scale_color_brewer(palette = "Set1") # Use a color palette
  #           return(ggplotly(p_gg))
  #         } else {
  #           # Map index back to dates
  #           index_date_map <- data.frame(Index = unique(decomp_df$Index), Date = date_mapping)
  #           decomp_df_dated <- left_join(decomp_df, index_date_map, by = "Index")
  #           
  #           p_gg <- ggplot(decomp_df_dated, aes(x = Date, y = value)) +
  #             geom_line(aes(color = .rownames)) +
  #             facet_grid(vars(.rownames), scales = "free_y", switch = "y") +
  #             labs(title = paste(decomp_title, ":", rv$current_entity), x = "Date", y = "") +
  #             theme_minimal() +
  #             theme(strip.placement = "outside", legend.position = "none", strip.text.y.left = element_text(angle = 0)) +
  #             scale_color_brewer(palette = "Set1")
  #           return(ggplotly(p_gg))
  #         }
  #         
  #       } else {
  #         return(plot_ly() %>% layout(title = "Decomposition preview failed"))
  #       }
  #       
  #     }, error = function(e) {
  #       plot_ly() %>% layout(title = paste("Error in decomposition preview:", e$message))
  #     })
  #     
  #     # --- Default view ---
  #   } else {
  #     # Default message when no preview type is selected
  #     return(plot_ly() %>% layout(title = "Select Transformation or Seasonality Method for Preview"))
  #   }
  # })
  
  
  # ===== Apply Transformation =====
  # observeEvent(input$apply_transform, {
  #   req(rv$processed_data)
  #   transform_method <- input$transform_method
  #   if (transform_method == "none") {
  #     showNotification("No transformation selected.", type = "message")
  #     # Log step? Optional, indicates user clicked but selected None.
  #     step_id <- paste0("transform_", format(Sys.time(), "%Y%m%d%H%M%S"))
  #     rv$preprocessing_steps[[step_id]] <- list(
  #       step = "Transformation", method = "None", lambda = NA, timestamp = Sys.time()
  #     )
  #     return()
  #   }
  #   
  #   lambda <- input$lambda # Get lambda value if Box-Cox
  #   showNotification(paste("Applying transformation:", transform_method), type="message", duration=2)
  #   
  #   withProgress(message = paste('Applying', transform_method, 'transformation...'), value = 0.1, {
  #     tryCatch({
  #       start_time <- Sys.time()
  #       
  #       # Check if Original_Volume exists, create it if not
  #       if (!"Original_Volume" %in% names(rv$processed_data)) {
  #         transformed_data_prep <- rv$processed_data %>% mutate(Original_Volume = Volume)
  #       } else {
  #         # If it exists, transformation replaces current Volume, keeps Original_Volume
  #         transformed_data_prep <- rv$processed_data
  #       }
  #       
  #       # Apply transformation group-wise if necessary (e.g., z-score, minmax)
  #       transformed_data <- transformed_data_prep %>%
  #         group_by(Entity_ID) %>% # Group for scaling methods
  #         mutate(
  #           Volume = case_when(
  #             transform_method == "log" ~ log(pmax(Volume, 1e-6)),
  #             transform_method == "sqrt" ~ sqrt(pmax(Volume, 0)),
  #             transform_method == "boxcox" ~ {
  #               min_vol <- min(Volume, na.rm = TRUE)
  #               offset <- if (!is.na(min_vol) && min_vol <= 0) abs(min_vol) + 1e-6 else 0
  #               if (length(unique(Volume[Volume > 0])) < 2) {
  #                 NA_real_ # Return NA if BoxCox cannot be fitted
  #               } else {
  #                 current_lambda <- if(is.na(lambda) || !is.numeric(lambda)) "auto" else lambda
  #                 forecast::BoxCox(Volume + offset, lambda = current_lambda)
  #               }
  #             },
  #             transform_method == "zscore" ~ {
  #               # scale returns a matrix/vector, ensure numeric
  #               scaled_vol <- scale(Volume)
  #               if(is.matrix(scaled_vol)) as.numeric(scaled_vol[,1]) else as.numeric(scaled_vol)
  #             },
  #             transform_method == "minmax" ~ {
  #               min_v <- min(Volume, na.rm = TRUE)
  #               max_v <- max(Volume, na.rm = TRUE)
  #               if (is.na(min_v) || is.na(max_v) || max_v == min_v) {
  #                 0.5 # Or NA
  #               } else {
  #                 (Volume - min_v) / (max_v - min_v)
  #               }
  #             },
  #             TRUE ~ Volume # Should not be reached if method != "none"
  #           ),
  #           # Ensure Volume remains numeric and handle potential NaNs
  #           Volume = ifelse(is.nan(Volume), NA_real_, as.numeric(Volume))
  #         ) %>%
  #         ungroup() # Ungroup after transformation
  #       
  #       incProgress(0.8)
  #       end_time <- Sys.time()
  #       
  #       # Log step
  #       step_id <- paste0("transform_", format(Sys.time(), "%Y%m%d%H%M%S"))
  #       rv$preprocessing_steps[[step_id]] <- list(
  #         step = "Transformation",
  #         method = transform_method,
  #         lambda = if (transform_method == "boxcox") lambda else NA,
  #         timestamp = Sys.time()
  #       )
  #       
  #       # Update data
  #       rv$processed_data <- transformed_data
  #       duration <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)
  #       showNotification(paste("Data transformed via", transform_method, "in", duration, "sec."), type = "message")
  #       
  #     }, error = function(e) {
  #       showNotification(paste("Error applying transformation:", e$message), type = "error", duration = 10)
  #     })
  #   })
  # })
  
  
  # ===== Apply Seasonal Adjustment =====
  # observeEvent(input$apply_seasonal, {
  #   req(rv$processed_data)
  #   decomp_method <- input$seasonality_method
  #   adjust <- input$adjust_seasonality
  #   
  #   if (!adjust || decomp_method == "none") {
  #     showNotification("No seasonal adjustment applied.", type = "message")
  #     # Log step?
  #     step_id <- paste0("seasonal_", format(Sys.time(), "%Y%m%d%H%M%S"))
  #     rv$preprocessing_steps[[step_id]] <- list(
  #       step = "Seasonal Adjustment", method = decomp_method, applied = FALSE, timestamp = Sys.time()
  #     )
  #     return()
  #   }
  #   
  #   seasonal_type <- input$seasonal_type # Additive or Multiplicative
  #   showNotification(paste("Applying seasonal adjustment:", decomp_method), type="message", duration=2)
  #   
  #   
  #   withProgress(message = paste('Applying seasonal adjustment via', decomp_method, '...'), value = 0.1, {
  #     tryCatch({
  #       start_time <- Sys.time()
  #       original_rows <- nrow(rv$processed_data)
  #       
  #       # Check if Original_Volume exists, create it if not
  #       if (!"Original_Volume" %in% names(rv$processed_data)) {
  #         data_to_adjust <- rv$processed_data %>% mutate(Original_Volume = Volume)
  #       } else {
  #         # If it exists, adjustment replaces current Volume, keeps Original_Volume
  #         data_to_adjust <- rv$processed_data
  #       }
  #       
  #       
  #       # Process data item by item
  #       adjusted_data_list <- list()
  #       all_item_ids <- unique(data_to_adjust$Entity_ID)
  #       num_entities <- length(all_item_ids)
  #       
  #       for(i in 1:num_entities) {
  #         item_id_current <- all_item_ids[i]
  #         item_df <- data_to_adjust %>% filter(Entity_ID == item_id_current) %>% arrange(Date)
  #         incProgress(0.8 / num_entities, detail = paste("Item:", first(item_df$Entity_Name)))
  #         
  #         # Get frequency for this item
  #         freq_details_item <- detect_frequency(item_df$Date)
  #         ts_freq_item <- freq_details_item$freq_numeric
  #         
  #         # Basic checks for seasonality application
  #         min_points_season <- 2 * ts_freq_item
  #         if (decomp_method == "stl") min_points_season <- min_points_season + 1
  #         
  #         if (ts_freq_item <= 1 || nrow(item_df) < min_points_season || sum(!is.na(item_df$Volume)) < min_points_season ) {
  #           warning(paste("Skipping seasonal adjustment for Item", item_id_current, "- insufficient data or frequency"))
  #           adjusted_data_list[[i]] <- item_df # Keep original data for this item
  #           next # Skip to next item
  #         }
  #         
  #         # Create time series object, handling NAs based on method
  #         ts_item <- ts(item_df$Volume, frequency = ts_freq_item)
  #         adjusted_volume_vec <- NULL # To store the adjusted series
  #         
  #         tryCatch({ # Inner tryCatch for decomposition errors per item
  #           if (decomp_method == "stl") {
  #             ts_item_imputed <- na.omit(ts_item) # STL needs complete series
  #             if (length(ts_item_imputed) < min_points_season) stop("Not enough non-NA after omit")
  #             decomp <- stl(ts_item_imputed, s.window = "periodic")
  #             adjusted_volume_vec <- seasadj(decomp) # Get seasonally adjusted series
  #             
  #           } else if (decomp_method == "decompose") {
  #             ts_item_imputed <- na.omit(ts_item) # Decompose needs complete series
  #             if (length(ts_item_imputed) < 2 * ts_freq_item) stop("Not enough non-NA after omit")
  #             decomp <- decompose(ts_item_imputed, type = tolower(seasonal_type))
  #             adjusted_volume_vec <- seasadj(decomp) # Use forecast's seasadj for convenience
  #             
  #           } else if (decomp_method == "ma") {
  #             # Manual MA adjustment (less common, might need refinement)
  #             ma_order <- floor(ts_freq_item / 2) * 2 + 1
  #             ma_order <- max(3, min(ma_order, length(ts_item) - 2))
  #             
  #             trend_comp <- stats::filter(ts_item, filter = rep(1 / ma_order, ma_order), sides = 2)
  #             seasonal_est <- ts_item - trend_comp # Estimate seasonal component
  #             # Need to average seasonal_est over periods, then subtract/divide
  #             # This is complex to do robustly here. STL or decompose is usually preferred.
  #             # For a simplified version, just remove trend? Or return trend?
  #             # Let's use seasadj(stl) as a fallback if MA selected? Or show error.
  #             # adjusted_volume_vec <- trend_comp # Or maybe ts_item - seasonal_est? Needs care.
  #             stop("MA seasonal adjustment application is complex; use STL or Decompose instead.")
  #           }
  #           
  #           # --- Map adjusted values back to original data frame ---
  #           if (!is.null(adjusted_volume_vec)) {
  #             # Get indices of non-NA values in the original ts_item
  #             original_indices <- which(!is.na(as.numeric(ts_item)))
  #             # Ensure length matches
  #             if (length(adjusted_volume_vec) == length(original_indices)) {
  #               # Create a full vector of NAs
  #               full_adjusted_vec <- rep(NA_real_, length(ts_item))
  #               # Fill in the adjusted values at the original non-NA positions
  #               full_adjusted_vec[original_indices] <- as.numeric(adjusted_volume_vec)
  #               # Assign back to the data frame column
  #               item_df$Volume <- full_adjusted_vec
  #             } else {
  #               warning(paste("Length mismatch after seasonal adjustment for Item", item_id_current))
  #               # Fallback: don't adjust this item if lengths don't match
  #             }
  #           }
  #         }, error = function(e_item) {
  #           warning(paste("Error adjusting seasonality for Item", item_id_current, ":", e_item$message))
  #           # Keep original data for this item on error
  #         })
  #         
  #         adjusted_data_list[[i]] <- item_df # Add (potentially modified) item df to list
  #       } # End loop through items
  #       
  #       # Combine adjusted data for all items
  #       adjusted_data_combined <- bind_rows(adjusted_data_list)
  #       
  #       end_time <- Sys.time()
  #       
  #       # Log step
  #       step_id <- paste0("seasonal_", format(Sys.time(), "%Y%m%d%H%M%S"))
  #       rv$preprocessing_steps[[step_id]] <- list(
  #         step = "Seasonal Adjustment", method = decomp_method, type = seasonal_type, applied = TRUE, timestamp = Sys.time()
  #       )
  #       
  #       # Update data
  #       rv$processed_data <- adjusted_data_combined
  #       duration <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)
  #       showNotification(paste("Seasonal adjustment applied via", decomp_method, "in", duration, "sec."), type = "message")
  #       
  #     }, error = function(e) {
  #       showNotification(paste("Error applying seasonal adjustment:", e$message), type = "error", duration = 10)
  #     }, warning = function(w) {
  #       # Capture warnings from the item loop
  #       showNotification(paste("Warning:", w$message), type = "warning", duration = 8)
  #     })
  #   })
  # })
  
  
  # ===== Time Aggregation Preview =====
  # Placeholder - requires implementation based on selected aggregation level/method
  output$aggregation_preview <- renderPlotly({
    req(rv$processed_data, rv$current_entity, input$data_aggregation)
    aggregation_level <- input$data_aggregation
    if (aggregation_level == "none") {
      return(plot_ly() %>% layout(title = "Select Aggregation Level for Preview"))
    }
    
    entity_data <- rv$processed_data %>% filter(Entity_Name == enc2utf8(rv$current_entity)) %>% arrange(Date)
    if(nrow(entity_data) < 2) return(plot_ly() %>% layout(title = "Not enough data"))
    
    tryCatch({
      aggregation_method <- input$agg_method
      agg_fun <- switch(aggregation_method,
                        "sum" = sum,
                        "mean" = mean,
                        "median" = median,
                        "max" = max,
                        "min" = min,
                        sum) # Default to sum
      
      aggregated_data <- entity_data # Start with item data
      
      # Apply aggregation based on level
      if (aggregation_level == "weekly") {
        aggregated_data <- aggregated_data %>%
          mutate(Week_Start = floor_date(Date, "week")) %>%
          group_by(Entity_ID, Entity_Name, Week_Start) %>%
          summarise(Aggregated_Volume = agg_fun(Volume, na.rm = TRUE), .groups = "drop") %>%
          rename(Date = Week_Start, Volume = Aggregated_Volume)
      } else if (aggregation_level == "monthly") {
        aggregated_data <- aggregated_data %>%
          mutate(Month_Start = floor_date(Date, "month")) %>%
          group_by(Entity_ID, Entity_Name, Month_Start) %>%
          summarise(Aggregated_Volume = agg_fun(Volume, na.rm = TRUE), .groups = "drop") %>%
          rename(Date = Month_Start, Volume = Aggregated_Volume)
      } else if (aggregation_level == "weekly_to_monthly"){
        # Assuming input is already weekly - check frequency? Or just apply floor_date
        aggregated_data <- aggregated_data %>%
          mutate(Month_Start = floor_date(Date, "month")) %>%
          group_by(Entity_ID, Entity_Name, Month_Start) %>%
          summarise(Aggregated_Volume = agg_fun(Volume, na.rm = TRUE), .groups = "drop") %>%
          rename(Date = Month_Start, Volume = Aggregated_Volume)
      } else if (aggregation_level == "custom") {
        period_days <- input$agg_period
        if(is.na(period_days) || period_days < 1) period_days <- 7 # Default safeguard
        aggregated_data <- aggregated_data %>%
          mutate(Period_Group = floor(as.numeric(Date - min(Date)) / period_days)) %>%
          group_by(Entity_ID, Entity_Name, Period_Group) %>%
          summarise(
            Date = min(Date), # Use start date of the period
            Aggregated_Volume = agg_fun(Volume, na.rm = TRUE),
            .groups = "drop"
          ) %>%
          select(-Period_Group) %>%
          rename(Volume = Aggregated_Volume)
      }
      
      # Plot original vs aggregated
      plot_ly() %>%
        add_trace(data = entity_data, x = ~Date, y = ~Volume, type = 'scatter', mode = 'lines', name = 'Original', line=list(color='grey', dash='dot')) %>%
        add_trace(data = aggregated_data, x = ~Date, y = ~Volume, type = 'scatter', mode = 'lines+markers', name = 'Aggregated', line = list(color = '#00a65a'), marker=list(size=4)) %>%
        layout(
          title = paste(
            "Aggregation Preview:",
            rv$current_entity,
            "-",
            aggregation_level
          ),
          xaxis = list(title = "Date"),
          yaxis = list(title = "Volume"),
          hovermode = "x unified"
        )
      
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error in aggregation preview:", e$message))
    })
  })
  
  # ===== Apply Time Aggregation =====
  # Placeholder - requires implementation
  observeEvent(input$apply_aggregation, {
    req(rv$processed_data, input$data_aggregation)
    aggregation_level <- input$data_aggregation
    
    if (aggregation_level == "none") {
      showNotification("No aggregation selected.", type = "message")
      return()
    }
    
    aggregation_method <- input$agg_method
    showNotification(paste("Applying aggregation:", aggregation_level, "using", aggregation_method), type="message", duration=2)
    
    withProgress(message = paste('Aggregating data to', aggregation_level, '...'), value = 0.1, {
      tryCatch({
        start_time <- Sys.time()
        original_rows <- nrow(rv$processed_data)
        
        agg_fun <- switch(aggregation_method, "sum"=sum, "mean"=mean, "median"=median, "max"=max, "min"=min, sum)
        data_to_aggregate <- rv$processed_data
        
        # Check if Original_Volume exists, create it if not - Aggregation should generally be done BEFORE transforms/adjustments
        # Warn user if Original_Volume exists?
        if ("Original_Volume" %in% names(data_to_aggregate)) {
          showNotification("Warning: Aggregating data that might have already been transformed/adjusted. Original values lost.", type="warning", duration=8)
          # Decide whether to aggregate 'Volume' or 'Original_Volume'. Let's aggregate current 'Volume'.
        }
        
        
        aggregated_data_list <- list()
        all_item_ids <- unique(data_to_aggregate$Entity_ID)
        num_entities <- length(all_item_ids)
        
        for(i in 1:num_entities) {
          item_id_current <- all_item_ids[i]
          item_df <- data_to_aggregate %>% filter(Entity_ID == item_id_current) %>% arrange(Date)
          incProgress(0.8 / num_entities, detail = paste("Item:", first(item_df$Entity_Name)))
          
          item_aggregated_df <- NULL
          
          if (aggregation_level == "weekly") {
            item_aggregated_df <- item_df %>%
              mutate(Week_Start = floor_date(Date, "week")) %>%
              group_by(Entity_ID, Entity_Name, Week_Start) %>%
              summarise(Volume = agg_fun(Volume, na.rm = TRUE), .groups = "drop") %>%
              rename(Date = Week_Start)
          } else if (aggregation_level == "monthly") {
            item_aggregated_df <- item_df %>%
              mutate(Month_Start = floor_date(Date, "month")) %>%
              group_by(Entity_ID, Entity_Name, Month_Start) %>%
              summarise(Volume = agg_fun(Volume, na.rm = TRUE), .groups = "drop") %>%
              rename(Date = Month_Start)
          } else if (aggregation_level == "weekly_to_monthly"){
            item_aggregated_df <- item_df %>%
              mutate(Month_Start = floor_date(Date, "month")) %>%
              group_by(Entity_ID, Entity_Name, Month_Start) %>%
              summarise(Volume = agg_fun(Volume, na.rm = TRUE), .groups = "drop") %>%
              rename(Date = Month_Start)
          } else if (aggregation_level == "custom") {
            period_days <- input$agg_period
            if(is.na(period_days) || period_days < 1) period_days <- 7
            item_aggregated_df <- item_df %>%
              mutate(Period_Group = floor(as.numeric(Date - min(Date)) / period_days)) %>%
              group_by(Entity_ID, Entity_Name, Period_Group) %>%
              summarise(Date = min(Date), Volume = agg_fun(Volume, na.rm = TRUE), .groups = "drop") %>%
              select(-Period_Group)
          } else {
            # Should not happen if aggregation_level != "none"
            item_aggregated_df <- item_df
          }
          aggregated_data_list[[i]] <- item_aggregated_df
        } # End item loop
        
        aggregated_data_combined <- bind_rows(aggregated_data_list)
        end_time <- Sys.time()
        rows_after <- nrow(aggregated_data_combined)
        
        # Log step
        step_id <- paste0("aggregation_", format(Sys.time(), "%Y%m%d%H%M%S"))
        rv$preprocessing_steps[[step_id]] <- list(
          step = "Aggregation",
          level = aggregation_level,
          method = aggregation_method,
          custom_period = if(aggregation_level == "custom") input$agg_period else NA,
          rows_before = original_rows,
          rows_after = rows_after,
          timestamp = Sys.time()
        )
        
        # Update data
        rv$processed_data <- aggregated_data_combined
        # Clear outliers as they are no longer valid after aggregation
        rv$outliers <- NULL
        
        duration <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)
        showNotification(paste("Data aggregated to", aggregation_level, "level in", duration, "sec."), type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error during aggregation:", e$message), type = "error", duration = 10)
      })
    })
    
  })
  
  
  # ===== Preprocessing Summary =====
  output$preprocessing_summary <- renderPrint({
    steps <- rv$preprocessing_steps
    if (length(steps) == 0) {
      cat("No preprocessing steps applied yet.")
      return()
    }
    cat("Applied Preprocessing Steps (in order):\n\n")
    # Sort steps by timestamp just in case they weren't added perfectly sequentially
    step_names_sorted <- names(steps)[order(sapply(steps, `[[`, "timestamp"))]
    
    for (i in 1:length(step_names_sorted)) {
      step_name <- step_names_sorted[i]
      step_info <- steps[[step_name]]
      cat(paste0(i, ". ", step_info$step, " (", format(step_info$timestamp, "%H:%M:%S"), "):\n"))
      
      details <- ""
      if (step_info$step == "Missing Values") details <- paste("   Method:", step_info$method, "| Rows Removed:", step_info$rows_removed)
      if (step_info$step == "Duplicates") details <- paste("   Method:", step_info$method, "| Rows Removed/Aggregated:", step_info$rows_removed)
      if (step_info$step == "Outliers") details <- paste("   Method:", step_info$detection_method, "| Threshold:", step_info$threshold, "| Action:", step_info$action, "| Found:", step_info$outliers_found, "| Removed:", step_info$rows_removed)
      if (step_info$step == "Value Replacement") details <- paste("   Condition:", step_info$condition, "| Replaced with:", step_info$replacement_value, "| Affected:", step_info$affected_count)
      if (step_info$step == "Aggregation") details <- paste("   Level:", step_info$level, "| Method:", step_info$method, if(!is.na(step_info$custom_period)) paste("| Period:", step_info$custom_period), "| Rows Before:", step_info$rows_before, "| Rows After:", step_info$rows_after)
      if (step_info$step == "Transformation") details <- paste("   Method:", step_info$method, if (!is.na(step_info$lambda)) paste("| Lambda:", step_info$lambda))
      if (step_info$step == "Seasonal Adjustment") details <- paste("   Method:", step_info$method, "| Type:", step_info$type, "| Applied:", step_info$applied)
      cat(details, "\n\n")
    }
  })
  
  # ===== Data Status Indicators =====
  output$data_status_indicators <- renderUI({
    # Requires rv$processed_data to be available
    req(rv$processed_data)
    data_current <- rv$processed_data
    
    # Calculate stats based on CURRENT processed data
    total_count <- nrow(data_current)
    missing_count <- sum(is.na(data_current$Volume))
    missing_pct <- if (total_count > 0) round(missing_count / total_count * 100, 1) else 0
    
    # Outliers are stored in rv$outliers, which might be from a previous state
    # Use the count from rv$outliers if it exists
    outlier_count <- if (!is.null(rv$outliers)) nrow(rv$outliers) else 0
    # Calculate outlier % based on data state *before* outlier removal (if it happened)
    # This requires finding the step where outliers were handled.
    outlier_step_info <- NULL
    if (length(rv$preprocessing_steps) > 0) {
      outlier_steps <- Filter(function(s) s$step == "Outliers", rv$preprocessing_steps)
      if (length(outlier_steps) > 0) {
        # Find the step *before* the first outlier removal/action
        # This logic is complex. Simpler: base % on count before *any* outlier action.
        # We need the row count just before the *first* outlier step was applied.
        outlier_step_timestamps <- sapply(rv$preprocessing_steps, function(s) if(s$step=="Outliers") s$timestamp else as.POSIXct(NA))
        first_outlier_time <- min(outlier_step_timestamps, na.rm=TRUE)
        
        # Find the state of the data just before this time. This is hard.
        # --- Simplification: Calculate % based on *original* data rows? ---
        # original_rows <- if(!is.null(rv$data)) nrow(rv$data) else total_count
        # outlier_pct <- if(original_rows > 0) round(outlier_count / original_rows * 100, 1) else 0
        
        # --- Alternative: Use rows_before from the first outlier step log ---
        first_outlier_step_name <- names(rv$preprocessing_steps)[which.min(outlier_step_timestamps)]
        rows_before_outlier <- total_count # Default if no outlier step found
        if(length(first_outlier_step_name) > 0 && !is.null(rv$preprocessing_steps[[first_outlier_step_name]]$rows_before)){
          # This assumes rows_before was logged, which wasn't in the original outlier handler
          # rows_before_outlier <- rv$preprocessing_steps[[first_outlier_step_name]]$rows_before
          # We need to calculate rows_before *when detecting*
          # Let's stick to % of *current* data for simplicity, acknowledging it might be misleading if rows were removed before outlier detection.
          outlier_pct <- if(total_count > 0) round(outlier_count / total_count * 100, 1) else 0
        } else {
          outlier_pct <- if(total_count > 0) round(outlier_count / total_count * 100, 1) else 0
        }
        
      } else {
        outlier_pct <- 0 # No outlier step applied yet
      }
    } else {
      outlier_pct <- 0 # No preprocessing steps at all
    }
    
    
    
    # Build the UI tags
    tagList(
      div(style="margin-bottom: 10px;",
          strong("Current Data State:"),
          p(style="font-size: 90%; color: #555;",
            "Records: ", total_count,
            ", Items: ", n_distinct(data_current$Entity_ID),
            ", Range: ", format(min(data_current$Date, na.rm=TRUE), "%Y-%m-%d"), " to ", format(max(data_current$Date, na.rm=TRUE), "%Y-%m-%d")
          )
      ),
      div(style="margin-bottom: 10px;",
          strong("Missing Values:"),
          div(class = "progress", style="height: 10px; margin-bottom: 3px;",
              div(class = paste("progress-bar", if(missing_pct > 10) "bg-danger" else if(missing_pct > 0) "bg-warning" else "bg-success"),
                  role = "progressbar", style = paste0("width:", missing_pct, "%;"))
          ),
          p(style="font-size: 90%; color: #555;",
            missing_count, " (", missing_pct, "%)",
            if(missing_count == 0) tags$i(class="fas fa-check-circle text-success", style="margin-left: 5px;") else ""
          )
      ),
      div(style="margin-bottom: 10px;",
          strong("Detected Outliers:"), # Reflects stored outliers, might not be in current data if removed/replaced
          div(class = "progress", style="height: 10px; margin-bottom: 3px;",
              div(class = paste("progress-bar", if(outlier_pct > 5) "bg-danger" else if(outlier_pct > 0) "bg-warning" else "bg-success"),
                  role = "progressbar", style = paste0("width:", min(100, outlier_pct * 5), "%;")) # Scale width visually
          ),
          p(style="font-size: 90%; color: #555;",
            outlier_count, " detected (approx ", outlier_pct, "% of current)", # Clarify % basis
            if(outlier_count == 0) tags$i(class="fas fa-check-circle text-success", style="margin-left: 5px;") else ""
          )
      ),
      div(style="margin-bottom: 10px;",
          strong("Preprocessing Applied:"),
          div(class = "progress", style="height: 10px; margin-bottom: 3px;",
              div(class = "progress-bar bg-info", role = "progressbar", style = paste0("width:", min(length(rv$preprocessing_steps) * 15, 100), "%;")) # Simple visual based on step count
          ),
          p(style="font-size: 90%; color: #555;", length(rv$preprocessing_steps), " step(s) applied")
      )
    )
  })
  
  # ===== Item Statistics (Current Entity) =====
  current_entity_stats <- reactive({
    req(rv$processed_data, rv$current_entity)
    
    entity_data <- rv$processed_data %>% filter(Entity_Name == rv$current_entity)
    if (nrow(entity_data) == 0) return(list(n = 0, mean = NA, sd = NA, missing = 0, missing_pct = 0, outliers = 0))
    
    missing_count <- sum(is.na(entity_data$Volume))
    n_obs <- nrow(entity_data)
    missing_pct_val <- if(n_obs > 0) round(missing_count / n_obs * 100, 1) else 0
    
    # Get outlier count specifically for *this* item from stored outliers
    outlier_count_item <- 0
    if (!is.null(rv$outliers)) {
      outlier_count_item <- nrow(rv$outliers %>% filter(Entity_Name == rv$current_entity))
    }
    
    list(
      n = n_obs,
      mean = round(mean(entity_data$Volume, na.rm = TRUE), 2),
      sd = round(sd(entity_data$Volume, na.rm = TRUE), 2),
      missing = missing_count,
      missing_pct = missing_pct_val,
      outliers = outlier_count_item
    )
  })
  
  # # Render UI elements for the stats boxes
  # render_stat_box <- function(value, subtitle, icon_name, color_class = "status-box-blue") {
  #   renderUI({
  #     # Ensure value is displayable, replace NA/NaN with "N/A"
  #     display_value <- if(is.na(value) || is.nan(value)) "N/A" else value
  #     div(class = paste("status-box", color_class),
  #         icon(icon_name), # Ensure fontawesome icons are available
  #         h4(display_value),
  #         p(subtitle))
  #   })
  # }
  
  # Modify your render_stat_box function to accept an icon_color parameter
  # Updated render_stat_box function with both icon color and background color
  # Render UI elements for the stats boxes
  # Updated render_stat_box function with both icon color and background color
  render_stat_box <- function(value, subtitle, icon_name, color_class = "status-box-blue", 
                              icon_color = NULL, bg_color = NULL) {
    renderUI({
      # Ensure value is displayable, replace NA/NaN with "N/A"
      display_value <- if(is.na(value) || is.nan(value)) "N/A" else value
      
      # Create the icon with optional color
      if (!is.null(icon_color)) {
        icon_element <- tags$i(class = paste0("fa fa-", icon_name), 
                               style = paste0("color:", icon_color, ";"))
      } else {
        icon_element <- icon(icon_name)
      }
      
      # Handle custom background color
      div_style <- NULL
      if (!is.null(bg_color)) {
        div_style <- paste0("background-color:", bg_color, ";")
      }
      
      div(class = paste("status-box", color_class),
          style = div_style,
          icon_element,
          h4(display_value),
          p(subtitle))
    })
  }
  
  output$stats_n_obs <- renderUI({
    req(rv$current_entity, rv$processed_data)
    stats <- current_entity_stats()
    
    # Create the stat box directly
    display_value <- if(is.na(stats$n) || is.nan(stats$n)) "N/A" else stats$n
    
    div(class = "status-box status-box-blue",
        tags$i(class = "fa fa-list-ol", style = "color: #2196F3; font-size: 24px;"),
        h4(display_value),
        p("Observations"))
  })
  
  output$stats_mean <- renderUI({
    req(rv$current_entity, rv$processed_data)
    stats <- current_entity_stats()
    
    # Create the stat box directly
    display_value <- if(is.na(stats$mean) || is.nan(stats$mean)) "N/A" else stats$mean
    
    div(class = "status-box status-box-purple",
        tags$i(class = "fa fa-calculator", style = "color: purple; font-size: 24px;"),
        h4(display_value),
        p("Mean Volume"))
  })
  
  output$stats_stdev <- renderUI({
    req(rv$current_entity, rv$processed_data)
    stats <- current_entity_stats()
    
    # Create the stat box directly
    display_value <- if(is.na(stats$sd) || is.nan(stats$sd)) "N/A" else stats$sd
    
    div(class = "status-box status-box-purple",
        tags$i(class = "fa fa-chart-line", style = "color: darkgreen; font-size: 24px;"),
        h4(display_value),
        p("Std Deviation"))
  })
  
  output$stats_missing <- renderUI({
    stats <- current_entity_stats()
    
    # Define icon color based on your preference
    icon_color <- if(stats$missing > 0) "darkred" else "#3c763d"  # darker yellow/green for better visibility
    
    # Create colored icon element
    colored_icon <- tags$i(
      class = "fa fa-question-circle",
      style = paste0("color:", icon_color, ";")
    )
    
    div(class = paste("status-box", if(stats$missing > 0) "status-box-yellow" else "status-box-green"),
        colored_icon,  # Use the colored icon instead of icon()
        h4(paste0(stats$missing, " (", stats$missing_pct, "%)")),
        p("Missing Values")
    )
  })
  output$stats_outliers <- renderUI({
    stats <- current_entity_stats()
    
    # Define icon color - use a color that will stand out against the background
    # Orange warning icon for outliers, green for no outliers
    icon_color <- if(stats$outliers > 0) "darkred" else "#ffffff"  # White icons for better visibility
    
    # Create colored icon element
    colored_icon <- tags$i(
      class = "fa fa-exclamation-triangle",
      style = paste0("color:", icon_color, ";")
    )
    
    div(class = paste("status-box", if(stats$outliers > 0) "status-box-orange" else "status-box-green"),
        colored_icon,  # Use the colored icon instead of icon()
        h4(stats$outliers),
        p("Detected Outliers")
    )
  })
  
  # ===== Apply All/Reset/Download Preprocessed =====
  observeEvent(input$apply_preprocessing, {
    # This button doesn't really "apply" anything new, it's more a conceptual check.
    # The data (rv$processed_data) is already updated by individual apply buttons.
    req(rv$processed_data)
    if (length(rv$preprocessing_steps) == 0) {
      showNotification("No preprocessing steps have been applied yet.", type = "warning")
    } else {
      showNotification("Current data reflects all applied preprocessing steps.", type = "message")
      # Could potentially re-run all logged steps here if desired, but complex.
    }
  })
  
  observeEvent(input$reset_preprocessing, {
    req(rv$data) # Need original data to reset to
    if(is.null(rv$data)){
      showNotification("Original data not available for reset.", type="error")
      return()
    }
    rv$processed_data <- rv$data # Reset processed data to original
    rv$preprocessing_steps <- list() # Clear steps log
    rv$outliers <- NULL # Clear detected outliers
    rv$forecast_generated <- FALSE # Reset forecast status as well
    rv$forecast_results <- NULL
    rv$model_objects <- list()
    rv$performance_metrics <- list()
    showNotification("Data reset to original state. Preprocessing log cleared.", type = "warning")
    # You might want to reset UI elements like outlier method/action to defaults here too
    updateSelectInput(session, "missing_treatment", selected = "linear")
    updateSelectInput(session, "duplicate_handling", selected = "keep")
    updateSelectInput(session, "outlier_method", selected = "iqr")
    updateSelectInput(session, "outlier_action", selected = "keep")
    updateSelectInput(session, "data_aggregation", selected = "none")
    updateSelectInput(session, "transform_method", selected = "none")
    updateSelectInput(session, "seasonality_method", selected = "none")
    
  })
  
  output$download_preprocessed <- downloadHandler(
    filename = function() {
      paste0("preprocessed_data_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      req(rv$processed_data)
      export_data <- rv$processed_data
      # Create a dataframe from the preprocessing steps log
      preprocessing_log_df <- data.frame(
        Order = integer(),
        Step = character(),
        Details = character(),
        Timestamp = character(),
        stringsAsFactors = FALSE
      )
      if (length(rv$preprocessing_steps) > 0) {
        step_names_sorted <- names(rv$preprocessing_steps)[order(sapply(rv$preprocessing_steps, `[[`, "timestamp"))]
        for (i in 1:length(step_names_sorted)) {
          step_name <- step_names_sorted[i]
          step_info <- rv$preprocessing_steps[[step_name]]
          details <- ""
          # Generate details string based on step type
          if (step_info$step == "Missing Values")
            details <- paste("Method:",
                             step_info$method,
                             "| Rows Removed:",
                             step_info$rows_removed)
          if (step_info$step == "Duplicates")
            details <- paste("Method:",
                             step_info$method,
                             "| Rows Removed/Aggregated:",
                             step_info$rows_removed)
          if (step_info$step == "Outliers")
            details <- paste(
              "Method:",
              step_info$detection_method,
              "| Threshold:",
              step_info$threshold,
              "| Action:",
              step_info$action,
              "| Found:",
              step_info$outliers_found,
              "| Removed:",
              step_info$rows_removed
            )
          if (step_info$step == "Aggregation")
            details <- paste(
              "Level:",
              step_info$level,
              "| Method:",
              step_info$method,
              if (!is.na(step_info$custom_period))
                paste("| Period:", step_info$custom_period),
              "| Rows Before:",
              step_info$rows_before,
              "| Rows After:",
              step_info$rows_after
            )
          if (step_info$step == "Transformation")
            details <- paste("Method:",
                             step_info$method,
                             if (!is.na(step_info$lambda))
                               paste("| Lambda:", step_info$lambda))
          if (step_info$step == "Seasonal Adjustment")
            details <- paste(
              "Method:",
              step_info$method,
              "| Type:",
              step_info$type,
              "| Applied:",
              step_info$applied
            )
          # Append to log dataframe
          preprocessing_log_df <- rbind(preprocessing_log_df, data.frame(
            Order = i,
            Step = step_info$step,
            Details = details,
            Timestamp = format(step_info$timestamp, "%Y-%m-%d %H:%M:%S")
          ))
        }
      }
      
      # Create list of data frames for Excel sheets
      sheets_list <- list("Processed_Data" = export_data)
      if(nrow(preprocessing_log_df) > 0) sheets_list[["Preprocessing_Log"]] <- preprocessing_log_df
      # Optionally include original data and outliers if they exist
      if (!is.null(rv$data) && !identical(rv$data, export_data)) {
        sheets_list[["Original_Data"]] <- rv$data
      }
      if (!is.null(rv$outliers) && nrow(rv$outliers) > 0) {
        # Ensure outliers df doesn't contain the 'is_outlier' flag or temporary columns
        sheets_list[["Detected_Outliers"]] <- rv$outliers %>% select(Date, Entity_ID, Entity_Name, Volume)
      }
      
      # Write to Excel
      tryCatch({
        write_xlsx(sheets_list, file)
      }, error = function(e) {
        showNotification(paste("Error creating Excel file:", e$message), type = "error")
        # Fallback to CSV if Excel fails?
        # write.csv(export_data, file, row.names = FALSE)
      })
    }
  )
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  #forecast page start
  
  
  # Reactive values - Assume this exists and is populated
  rv <- reactiveValues(
    data = NULL,              # Assume populated
    processed_data = NULL,    # Assume populated/modified by Preprocessing
    outliers = NULL,          # Assume populated/cleared by Preprocessing
    forecast_results = NULL,  # Populated by this tab's logic
    model_objects = list(),   # Populated by this tab's logic
    performance_metrics = list(), # Populated by this tab's logic
    error_message = NULL,
    preprocessing_steps = list(), # Assume exists
    current_entity = NULL,      # Set/Synced here
    data_loaded = FALSE,      # Assume set
    forecast_generated = FALSE, # Set by this tab's logic
    comparison_metrics = NULL # Needed for CV output if enabled
    # Other rv elements...
  )
  
 
  # ===== Forecast Tab Server Logic =====
  
  # ===== Helper function to detect frequency =====
  detect_frequency <- function(dates) {
    if (length(dates) < 2) return(list(freq_numeric = 1, freq_unit = "day"))
    
    # Ensure dates are Date objects and sorted
    dates <- as.Date(dates)
    dates <- sort(unique(dates))
    
    # Calculate differences between consecutive dates
    diffs <- as.numeric(diff(dates))
    
    # Handle case where all dates are the same
    if (length(diffs) == 0 || all(is.na(diffs))) {
      return(list(freq_numeric = 1, freq_unit = "day"))
    }
    
    # Find most common difference
    diff_table <- table(diffs)
    if (length(diff_table) == 0) {
      modal_diff <- median(diffs, na.rm = TRUE)
    } else {
      modal_diff <- as.numeric(names(diff_table)[which.max(diff_table)])
    }
    
    # Handle NA or zero modal difference
    if (is.na(modal_diff) || modal_diff <= 0) {
      modal_diff <- median(diffs, na.rm = TRUE)
      if (is.na(modal_diff) || modal_diff <= 0) {
        return(list(freq_numeric = 1, freq_unit = "day"))
      }
    }
    
    # Map to common time series frequencies
    if (modal_diff >= 28 && modal_diff <= 31) {
      return(list(freq_numeric = 12, freq_unit = "month"))
    } else if (modal_diff >= 7 && modal_diff < 10) {
      return(list(freq_numeric = 52, freq_unit = "week"))
    } else if (modal_diff >= 85 && modal_diff < 95) {
      return(list(freq_numeric = 4, freq_unit = "quarter"))
    } else if (modal_diff >= 360 && modal_diff < 370) {
      return(list(freq_numeric = 1, freq_unit = "year"))
    } else if (modal_diff <= 1.5) {
      return(list(freq_numeric = 7, freq_unit = "day"))
    } else {
      # For other frequencies, estimate sensibly
      guessed_freq <- round(365.25 / modal_diff)
      unit <- if(guessed_freq > 1) paste(modal_diff,"-day",sep="") else "other"
      return(list(freq_numeric = max(1, guessed_freq), freq_unit = unit))
    }
  }
  
  # ===== Helper function to get frequency details =====
  get_current_frequency <- reactive({
    req(rv$processed_data)
    # Use forecast_entity as the relevant item selector for this tab
    req(input$forecast_entity)
    current_entity_name <- input$forecast_entity
    
    entity_data <- tryCatch({
      rv$processed_data %>% filter(Entity_Name == current_entity_name) %>% arrange(Date)
    }, error = function(e) { NULL })
    
    if (is.null(entity_data) || nrow(entity_data) < 2) {
      return(list(freq_numeric = 1, freq_unit = "day")) # Default
    }
    
    if (input$auto_frequency) {
      return(detect_frequency(entity_data$Date))
    } else {
      # Use the value from the frequency dropdown
      user_freq_input <- as.numeric(input$frequency)
      # Map the dropdown value (approx days) back to frequency number and unit
      freq_details <- case_when(
        user_freq_input == 30  ~ list(freq_numeric = 12, freq_unit = "month"),
        user_freq_input == 7   ~ list(freq_numeric = 52, freq_unit = "week"), # Use 52 for weekly
        user_freq_input == 91  ~ list(freq_numeric = 4, freq_unit = "quarter"), # Approx 91 days
        user_freq_input == 365 ~ list(freq_numeric = 1, freq_unit = "year"),
        user_freq_input == 1   ~ list(freq_numeric = 7, freq_unit = "day"), # Use 7 for daily ts
        TRUE ~ list(freq_numeric = 1, freq_unit = "other") # Default for unexpected values
      )
      # Override unit for Prophet if needed
      if (user_freq_input == 1) freq_details$freq_unit <- "day"
      if (user_freq_input == 7) freq_details$freq_unit <- "week"
      
      return(freq_details)
    }
  })
  
  # ===== Sync item selection across tabs =====
  observeEvent(input$forecast_entity, {
    req(input$forecast_entity)
    if (is.null(rv$current_entity) || input$forecast_entity != rv$current_entity) {
      rv$current_entity <- input$forecast_entity
      # Update others if they exist
      tryCatch({ if (input$selectentity != rv$current_entity) updateSelectizeInput(session, "selectentity", selected = rv$current_entity) }, error = function(e) {})
      tryCatch({ if (input$results_entity != rv$current_entity) updateSelectizeInput(session, "results_entity", selected = rv$current_entity) }, error = function(e) {})
      tryCatch({ if (input$diagnostics_entity != rv$current_entity) updateSelectizeInput(session, "diagnostics_entity", selected = rv$current_entity) }, error = function(e) {})
    }
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  
  # ===== Forecast Preview =====
  output$forecast_preview <- renderPlotly({
    req(rv$processed_data, input$forecast_entity)
    # Trigger the preview when the button is clicked OR when relevant inputs change
    input$update_preview
    # Use isolate() to prevent re-rendering on *every* input change, only on button click
    isolate({
      entity_name_preview <- input$forecast_entity
      entity_data <- rv$processed_data %>% filter(Entity_Name == enc2utf8(entity_name_preview)) %>% arrange(Date)
      
      # Determine minimum data points needed
      min_data_points <- case_when(
        input$method == "Prophet" ~ 15,
        input$method == "ARIMA" && !input$auto_arima && input$seasonal_arima && input$S_value > 1 ~ 2 * input$S_value + 5,
        input$method == "Exponential Smoothing" && !input$auto_ets && grepl("[AM]", substr(input$ets_model, 3, 3)) ~ 2 * (get_current_frequency()$freq_numeric) + 5,
        TRUE ~ 10 # Default minimum
      )
      min_data_points <- max(5, min_data_points) # Absolute minimum
      
      if (nrow(entity_data) < min_data_points) {
        return(
          plot_ly() %>% layout(
            title = paste("Not enough data for", input$method, "preview"),
            annotations = list(x = 0.5, y = 0.5, text = paste("Need at least", min_data_points, "data points"), showarrow = FALSE, font = list(size = 16))
          )
        )
      }
      
      # Get frequency details for the current item and method
      freq_details <- get_current_frequency()
      ts_freq <- freq_details$freq_numeric
      prophet_freq_unit <- freq_details$freq_unit
      
      # Limit preview horizon for speed
      horizon_preview <- min(input$h_value, 30)
      forecast_obj_preview <- NULL
      prophet_forecast_df <- NULL
      fit_preview <- NULL
      
      tryCatch({
        # --- Fit model based on selected method ---
        if (input$method == "ARIMA") {
          # Ensure data is valid before creating ts object
          entity_data <- entity_data %>% 
            filter(!is.na(Volume), is.finite(Volume)) %>%
            arrange(Date)
          
          if (nrow(entity_data) < min_data_points) {
            return(plot_ly() %>% layout(title = paste("Not enough data for", input$method, "preview")))
          }
          
          # Create ts object with proper frequency
          ts_data <- ts(entity_data$Volume, frequency = ts_freq)
          
          if (input$auto_arima) {
            # Use auto.arima with robust defaults for preview
            fit_preview <- tryCatch({
              auto.arima(ts_data, 
                         stepwise = TRUE,
                         approximation = TRUE,
                         max.p = 5,
                         max.q = 5,
                         max.P = 2, 
                         max.Q = 2,
                         max.order = 5,
                         max.d = 2,
                         max.D = 1)
            }, error = function(e) {
              # Simple fallback model if auto.arima fails
              arima(ts_data, order = c(1,1,1), seasonal = list(order = c(0,0,0), period = ts_freq))
            })
          } else {
            # Manual ARIMA with user-specified parameters
            p <- input$p_value
            d <- input$d_value
            q <- input$q_value
            
            if (input$seasonal_arima) {
              P <- input$P_value
              D <- input$D_value
              Q <- input$Q_value
              S <- input$S_value
              
              fit_preview <- tryCatch({
                Arima(ts_data, 
                      order = c(p, d, q), 
                      seasonal = list(order = c(P, D, Q), period = S))
              }, error = function(e) {
                # Fallback to simpler model
                arima(ts_data, order = c(p, d, q))
              })
            } else {
              fit_preview <- tryCatch({
                arima(ts_data, order = c(p, d, q))
              }, error = function(e) {
                # Fallback to default
                arima(ts_data, order = c(1, 1, 1))
              })
            }
          }
          
          # Generate forecast with proper error handling
          forecast_obj_preview <- tryCatch({
            forecast(fit_preview, h = horizon_preview, level = input$prediction_interval)
          }, error = function(e) {
            # Basic manual forecast if forecast function fails
            preds <- predict(fit_preview, n.ahead = horizon_preview)
            structure(
              list(
                mean = preds$pred,
                lower = matrix(preds$pred - 1.96 * preds$se, ncol = 1),
                upper = matrix(preds$pred + 1.96 * preds$se, ncol = 1),
                level = input$prediction_interval,
                x = ts_data
              ),
              class = "forecast"
            )
          })
          
        } else if (input$method == "Exponential Smoothing") {
          ts_data <- ts(entity_data$Volume, frequency = ts_freq)
          if (length(na.omit(ts_data)) < min_data_points) stop("Not enough non-NA data.")
          
          if (input$auto_ets) {
            fit_preview <- ets(ts_data, allow.multiplicative.trend = FALSE)
          } else {
            fit_preview <- ets(ts_data, model = input$ets_model,
                               alpha = input$alpha,
                               beta = input$beta,
                               gamma = input$gamma,
                               allow.multiplicative.trend = FALSE)
          }
          forecast_obj_preview <- forecast(fit_preview, h = horizon_preview, level = input$prediction_interval)
          
        } else if (input$method == "Prophet") {
          prophet_data <- data.frame(ds = entity_data$Date, y = entity_data$Volume) %>% filter(!is.na(y))
          
          # Add selected regressors to prophet_data for preview
          selected_regressors <- input$selected_regressors
          if (!is.null(selected_regressors) && length(selected_regressors) > 0) {
            for (regressor_col in selected_regressors) {
              if (regressor_col %in% colnames(entity_data)) {
                prophet_data[[regressor_col]] <- entity_data[[regressor_col]][!is.na(entity_data$Volume)]
              }
            }
          }
          
          if (nrow(prophet_data) < min_data_points) stop("Not enough non-NA data for Prophet.")
          
          n_obs_prophet <- nrow(prophet_data)
          potential_cps <- max(0, floor(n_obs_prophet * 0.8) - 1)
          n_changepoints_adjusted <- min(15, potential_cps)
          
          # Create Prophet model with data - the traditional approach
          if (!is.null(selected_regressors) && length(selected_regressors) > 0) {
            # Initialize prophet model first when using regressors
            m <- prophet(
              n.changepoints = n_changepoints_adjusted,
              changepoint.prior.scale = input$changepoint_prior,
              seasonality.prior.scale = input$seasonality_prior,
              yearly.seasonality = input$yearly_seasonality,
              weekly.seasonality = input$weekly_seasonality,
              daily.seasonality = input$daily_seasonality,
              interval.width = input$prediction_interval / 100,
              uncertainty.samples = 50
            )
            
            # Add regressors to the model
            for (regressor_col in selected_regressors) {
              if (regressor_col %in% colnames(prophet_data)) {
                m <- add_regressor(m, regressor_col)
              }
            }
            
            # Fit the model with data
            fit_preview <- fit.prophet(m, prophet_data)
          } else {
            # Use original direct approach when no regressors
            fit_preview <- prophet(
              prophet_data,
              n.changepoints = n_changepoints_adjusted,
              changepoint.prior.scale = input$changepoint_prior,
              seasonality.prior.scale = input$seasonality_prior,
              yearly.seasonality = input$yearly_seasonality,
              weekly.seasonality = input$weekly_seasonality,
              daily.seasonality = input$daily_seasonality,
              interval.width = input$prediction_interval / 100,
              uncertainty.samples = 50
            )
          }
          
          # Make future dataframe
          future <- make_future_dataframe(fit_preview, periods = horizon_preview, freq = prophet_freq_unit)
          
          # Add regressor values to future dataframe for preview
          if (!is.null(selected_regressors) && length(selected_regressors) > 0) {
            for (regressor_col in selected_regressors) {
              if (regressor_col %in% colnames(prophet_data)) {
                last_value <- tail(prophet_data[[regressor_col]], 1)
                if (length(last_value) > 0 && !is.na(last_value)) {
                  future[[regressor_col]] <- c(prophet_data[[regressor_col]], rep(last_value, horizon_preview))
                } else {
                  mean_value <- mean(prophet_data[[regressor_col]], na.rm = TRUE)
                  future[[regressor_col]] <- c(prophet_data[[regressor_col]], rep(ifelse(is.na(mean_value), 0, mean_value), horizon_preview))
                }
              }
            }
          }
          
          prophet_forecast_df <- predict(fit_preview, future)
          
          # Structure forecast output like forecast() object for plotting consistency
          forecast_mean <- tail(prophet_forecast_df$yhat, horizon_preview)
          forecast_lower <- tail(prophet_forecast_df$yhat_lower, horizon_preview)
          forecast_upper <- tail(prophet_forecast_df$yhat_upper, horizon_preview)
          
          forecast_obj_preview <- list(
            mean = forecast_mean,
            lower = matrix(forecast_lower, ncol = 1, dimnames=list(NULL, paste0("Lo ", input$prediction_interval))),
            upper = matrix(forecast_upper, ncol = 1, dimnames=list(NULL, paste0("Hi ", input$prediction_interval))),
            level = input$prediction_interval,
            x = ts(entity_data$Volume, frequency = ts_freq),
            method = "Prophet"
          )
          class(forecast_obj_preview) <- "forecast"
        }
        
        # --- Plotting ---
        if (!is.null(forecast_obj_preview)) {
          # Use forecast:::plot.forecast logic adapted for plotly
          p <- plot_ly() %>%
            add_trace(x = entity_data$Date, y = entity_data$Volume, type = 'scatter', mode = 'lines',
                      line = list(color = '#3c8dbc', width = 2), name = 'Historical')
          
          # Calculate forecast dates based on last historical date and frequency unit
          last_date <- max(entity_data$Date)
          
          # Generate forecast dates based on frequency unit
          if (prophet_freq_unit == "day") {
            forecast_dates <- seq.Date(from = last_date + 1, by = "day", length.out = horizon_preview)
          } else if (prophet_freq_unit == "week") {
            forecast_dates <- seq.Date(from = floor_date(last_date, "week") + weeks(1), by = "week", length.out = horizon_preview)
          } else if (prophet_freq_unit == "month") {
            forecast_dates <- seq.Date(from = floor_date(last_date, "month") %m+% months(1), by = "month", length.out = horizon_preview)
          } else if (prophet_freq_unit == "quarter") {
            forecast_dates <- seq.Date(from = floor_date(last_date, "quarter") %m+% months(3), by = "quarter", length.out = horizon_preview)
          } else if (prophet_freq_unit == "year") {
            forecast_dates <- seq.Date(from = floor_date(last_date, "year") %m+% years(1), by = "year", length.out = horizon_preview)
          } else {
            # Default to daily if unit is other/unknown
            forecast_dates <- seq.Date(from = last_date + 1, by = "day", length.out = horizon_preview)
          }
          
          # Add forecast line
          p <- p %>% add_trace(
            x = forecast_dates, y = forecast_obj_preview$mean, type = 'scatter', mode = 'lines',
            line = list(color = '#00a65a', width = 2, dash = 'dash'), name = 'Forecast'
          )
          
          # Add prediction intervals if requested and available
          if (input$use_prediction_intervals && !is.null(forecast_obj_preview$lower) && !is.null(forecast_obj_preview$upper)) {
            lower_bound <- forecast_obj_preview$lower[, 1] # Assumes first column is the desired level
            upper_bound <- forecast_obj_preview$upper[, 1]
            interval_name = paste0(input$prediction_interval,"% Interval")
            p <- p %>% add_trace(
              x = c(forecast_dates, rev(forecast_dates)),
              y = c(lower_bound, rev(upper_bound)),
              type = 'scatter', mode = 'lines',
              fill = 'toself', fillcolor = 'rgba(0, 166, 90, 0.2)',
              line = list(color = 'transparent'), showlegend = TRUE, # Show interval in legend
              name = interval_name
            )
          }
          
          # Set layout, zoom into recent history + forecast
          history_range = max(min(entity_data$Date), last_date - years(2)) # Show max 2 years history
          p <- p %>% layout(
            title = paste("Forecast Preview for", entity_name_preview),
            xaxis = list(title = "Date", range = c(history_range, max(forecast_dates))),
            yaxis = list(title = "Volume"),
            hovermode = "x unified",
            showlegend = TRUE
          )
          return(p)
          
        } else {
          stop("Forecast object could not be generated for preview.")
        }
        
      }, error = function(e) {
        showNotification(paste("Preview Error:", e$message), type = "error", duration = 10)
        return(
          plot_ly() %>% layout(
            title = "Error generating forecast preview",
            annotations = list(x = 0.5, y = 0.5, text = paste("Error:", e$message), showarrow = FALSE)
          )
        )
      })
    }) # End isolate
  }) # End renderPlotly
  
  # ===== Update Preview Button =====
  observeEvent(input$update_preview, {
    # The action of this button is handled by renderPlotly above
    showNotification("Updating preview...", type = "message", duration = 2)
  })
  
  # ===== Helper function to calculate performance metrics =====
  calculate_metrics <- function(actual, predicted) {
    # Ensure inputs are numeric vectors of the same length
    if (!is.numeric(actual) || !is.numeric(predicted) || length(actual) != length(predicted)) {
      warning("Invalid input for calculate_metrics")
      return(list(MAE = NA, RMSE = NA, MAPE = NA))
    }
    
    # Remove NA/Inf values pairwise
    valid_idx <- !is.na(actual) & !is.na(predicted) & is.finite(actual) & is.finite(predicted)
    if (sum(valid_idx) == 0) {
      return(list(MAE = NA, RMSE = NA, MAPE = NA))
    }
    actual <- actual[valid_idx]
    predicted <- predicted[valid_idx]
    
    errors <- actual - predicted
    mae <- mean(abs(errors))
    rmse <- sqrt(mean(errors^2))
    
    # Calculate MAPE, avoiding division by zero
    actual_nonzero_idx <- actual != 0
    if (sum(actual_nonzero_idx) > 0) {
      mape <- mean(abs(errors[actual_nonzero_idx] / actual[actual_nonzero_idx])) * 100
      mape <- ifelse(is.finite(mape), mape, NA) # Handle cases where MAPE might still be Inf/NaN
    } else {
      mape <- NA # MAPE is undefined if all actual values are zero
    }
    
    return(list(MAE = round(mae, 4), RMSE = round(rmse, 4), MAPE = round(mape, 4)))
  }
  
  # ===== Run Forecast (Main Action Button 'go') =====
  observeEvent(input$go, {
    req(rv$processed_data) # Need processed data to forecast
    showNotification("Starting forecast process...", type="message", duration=3)
    
    withProgress(message = 'Running forecasts...', value = 0, {
      tryCatch({
        # --- Determine Items to Forecast ---
        entities_to_forecast <- NULL
        if (input$batch_forecast) {
          entities_to_forecast <- unique(rv$processed_data$Entity_Name)
          if (length(entities_to_forecast) == 0) stop("No items found in processed data.")
          incProgress(0.05, detail = paste("Preparing batch for", length(entities_to_forecast), "items"))
        } else {
          req(input$forecast_entity) # Need single item selection if not batch
          if (!input$forecast_entity %in% unique(rv$processed_data$Entity_Name)) {
            stop(paste("Selected forecast item '", input$forecast_entity, "' not found in processed data."))
          }
          entities_to_forecast <- input$forecast_entity
          incProgress(0.05, detail = paste("Preparing forecast for:", entities_to_forecast))
        }
        
        # --- Initialize Results Storage ---
        forecast_results_list <- list()
        performance_metrics_list <- list()
        model_objects_list <- list()
        cv_results_list <- list() # For cross-validation if enabled
        
        total_entities <- length(entities_to_forecast)
        progress_per_item <- 0.9 / total_entities # Allocate 90% of progress bar to item loop
        
        # --- Loop Through Items ---
        for (i in 1:total_entities) {
          current_entity_name <- entities_to_forecast[i]
          incProgress(progress_per_item * 0.2, detail = paste("Forecasting:", current_entity_name, "(", i, "/", total_entities, ")"))
          
          # Filter data for the current item
          entity_data <- rv$processed_data %>%
            filter(Entity_Name == current_entity_name) %>%
            arrange(Date) %>%
            filter(!is.na(Volume)) # Ensure no NAs are passed to models
          
          # --- Get Forecast Settings for this Item ---
          freq_details_item <- detect_frequency(entity_data$Date)
          ts_freq <- freq_details_item$freq_numeric
          prophet_freq_unit <- freq_details_item$freq_unit
          horizon <- input$h_value
          pred_interval_level <- input$prediction_interval / 100 # Convert % to proportion
          
          # --- Check Data Adequacy ---
          min_data_points <- case_when(
            input$method == "Prophet" ~ 15,
            input$method == "ARIMA" && !input$auto_arima && input$seasonal_arima && input$S_value > 1 ~ 2 * input$S_value + 5,
            input$method == "Exponential Smoothing" && !input$auto_ets && grepl("[AM]", substr(input$ets_model, 3, 3)) ~ 2 * ts_freq + 5,
            TRUE ~ 10
          )
          min_data_points <- max(5, min_data_points)
          
          if (nrow(entity_data) < min_data_points) {
            warning(paste("Skipping", current_entity_name, "- needs at least", min_data_points, "non-NA points for", input$method))
            next # Skip to next item
          }
          
          # --- Fit Model and Forecast ---
          fit_model <- NULL
          forecast_output <- NULL
          forecast_raw <- NULL # Store raw forecast object
          
          incProgress(progress_per_item * 0.4, detail = paste("Fitting model for:", current_entity_name))
          
          tryCatch({ # Inner tryCatch for model fitting/forecasting errors per item
            if (input$method == "ARIMA") {
              # Create ts object with proper frequency
              ts_data <- ts(entity_data$Volume, frequency = ts_freq)
              
              # Check for valid data
              if (sum(!is.na(ts_data)) < min_data_points) {
                warning(paste("Insufficient data points for", current_entity_name))
                next
              }
              
              # Initialize model and forecast objects
              fit_model <- NULL
              forecast_raw <- NULL
              
              if (input$auto_arima) {
                # Auto ARIMA approach with robust parameters
                fit_model <- tryCatch({
                  auto.arima(ts_data,
                             stepwise = TRUE,       # Faster computation
                             approximation = TRUE,  # Use approximations for speed
                             max.p = 5,             # Limit model complexity
                             max.q = 5,
                             max.P = 2, 
                             max.Q = 2,
                             max.order = 5,         # Limit total parameters
                             max.d = 2,             # Limit differencing
                             max.D = 1)
                }, error = function(e) {
                  # If complex auto.arima fails, try a simpler version
                  tryCatch({
                    auto.arima(ts_data, d = 1, D = 0, max.p = 2, max.q = 2, max.P = 0, max.Q = 0, seasonal = FALSE)
                  }, error = function(e2) {
                    # If all auto methods fail, fall back to simple ARIMA(1,1,1)
                    arima(ts_data, order = c(1, 1, 1))
                  })
                })
              } else {
                # Manual ARIMA with user parameters
                p <- input$p_value
                d <- input$d_value
                q <- input$q_value
                
                if (input$seasonal_arima) {
                  P <- input$P_value
                  D <- input$D_value
                  Q <- input$Q_value
                  S <- input$S_value
                  
                  fit_model <- tryCatch({
                    Arima(ts_data, 
                          order = c(p, d, q), 
                          seasonal = list(order = c(P, D, Q), period = S))
                  }, error = function(e) {
                    # Fallback to non-seasonal
                    warning(paste("Seasonal ARIMA failed for", current_entity_name, ", trying non-seasonal."))
                    arima(ts_data, order = c(p, d, q))
                  })
                } else {
                  fit_model <- tryCatch({
                    arima(ts_data, order = c(p, d, q))
                  }, error = function(e) {
                    # Fallback to default
                    warning(paste("ARIMA with specified parameters failed for", current_entity_name, ", using default."))
                    arima(ts_data, order = c(1, 1, 1))
                  })
                }
              }
              
              # Generate forecast with robust error handling
              if (!is.null(fit_model)) {
                forecast_raw <- tryCatch({
                  forecast(fit_model, h = horizon, level = input$prediction_interval)
                }, error = function(e) {
                  # If forecast() fails, try predict() as a fallback
                  warning(paste("forecast() failed for", current_entity_name, ", using predict() as fallback."))
                  preds <- predict(fit_model, n.ahead = horizon)
                  
                  # Convert predict output to forecast-like structure
                  lower <- upper <- numeric(horizon)
                  pi_z <- qnorm(0.5 + input$prediction_interval/200)
                  
                  for (i in 1:horizon) {
                    se <- sqrt(preds$se[i]^2)
                    lower[i] <- preds$pred[i] - pi_z * se
                    upper[i] <- preds$pred[i] + pi_z * se
                  }
                  
                  # Create a forecast-like object
                  structure(
                    list(
                      mean = preds$pred,
                      lower = matrix(lower, ncol = 1),
                      upper = matrix(upper, ncol = 1),
                      level = input$prediction_interval,
                      x = ts_data,
                      method = paste("ARIMA(", paste(fit_model$arma[1:3], collapse=","), ")", sep="")
                    ),
                    class = "forecast"
                  )
                })
              } else {
                warning(paste("Failed to fit ARIMA model for", current_entity_name))
                next # Skip to next item
              }
              
            } else if (input$method == "Exponential Smoothing") {
              ts_data <- ts(entity_data$Volume, frequency = ts_freq)
              if (input$auto_ets) {
                fit_model <- tryCatch({
                  ets(ts_data)
                }, error = function(e) {
                  warning(paste("Auto ETS failed for", current_entity_name, ":", e$message))
                  # Fallback to simple exponential smoothing if auto fails
                  ets(ts_data, model = "ANN")
                })
              } else {
                # Manual ETS model selection
                fit_model <- tryCatch({
                  ets(ts_data, model = input$ets_model,
                      alpha = input$alpha,
                      beta = input$beta,
                      gamma = input$gamma)
                }, error = function(e) {
                  warning(paste("ETS with specified model failed for", current_entity_name, ":", e$message))
                  # Fallback to simple exponential smoothing
                  ets(ts_data, model = "ANN")
                })
              }
              
              if (!is.null(fit_model)) {
                forecast_raw <- tryCatch({
                  forecast(fit_model, h = horizon, level = input$prediction_interval)
                }, error = function(e) {
                  warning(paste("ETS forecast failed for", current_entity_name, ":", e$message))
                  NULL
                })
              }
              
              if (is.null(forecast_raw)) {
                warning(paste("Failed to generate ETS forecast for", current_entity_name))
                next # Skip to next item
              }
              
            } else if (input$method == "Prophet") {
              prophet_data <- data.frame(ds = entity_data$Date, y = entity_data$Volume)
              
              # Add selected regressors to prophet_data
              selected_regressors <- input$selected_regressors
              if (!is.null(selected_regressors) && length(selected_regressors) > 0) {
                for (regressor_col in selected_regressors) {
                  if (regressor_col %in% colnames(entity_data)) {
                    prophet_data[[regressor_col]] <- entity_data[[regressor_col]]
                  }
                }
              }
              
              # Adjust changepoints based on data size
              n_obs_prophet <- nrow(prophet_data)
              potential_cps <- max(0, floor(n_obs_prophet * 0.8) - 1)
              n_changepoints_adjusted <- min(25, potential_cps)
              
              # ===== NEW: Get optimized parameters for this item =====
              if (input$auto_optimize_prophet) {
                # Calculate item-specific optimized parameters
                tryCatch({
                  optimized_params <- calculate_prophet_parameters(entity_data)
                  changepoint_prior_item <- optimized_params$changepoint_prior
                  seasonality_prior_item <- optimized_params$seasonality_prior
                  
                  # Log optimization for batch processing
                  if (input$batch_forecast) {
                    cat("Prophet auto-optimization for", current_entity_name, ":\n")
                    cat("  Changepoint Prior:", changepoint_prior_item, 
                        "(Volatility CV:", round(optimized_params$volatility_cv, 3), ")\n")
                    cat("  Seasonality Prior:", seasonality_prior_item, 
                        "(Seasonal Strength:", round(optimized_params$seasonal_strength, 3), ")\n")
                  }
                  
                }, error = function(e) {
                  warning("Parameter optimization failed for ", current_entity_name, ": ", e$message)
                  # Fallback to UI values
                  changepoint_prior_item <- input$changepoint_prior
                  seasonality_prior_item <- input$seasonality_prior
                })
              } else {
                # Use UI slider values when auto-optimization is off
                changepoint_prior_item <- input$changepoint_prior
                seasonality_prior_item <- input$seasonality_prior
              }
              
              fit_model <- tryCatch({
                if (!is.null(selected_regressors) && length(selected_regressors) > 0) {
                  # Initialize prophet model first when using regressors
                  m <- prophet(
                    n.changepoints = n_changepoints_adjusted,
                    changepoint.prior.scale = changepoint_prior_item,  # Use item-specific value
                    seasonality.prior.scale = seasonality_prior_item,  # Use item-specific value
                    yearly.seasonality = input$yearly_seasonality,
                    weekly.seasonality = input$weekly_seasonality,
                    daily.seasonality = input$daily_seasonality,
                    interval.width = pred_interval_level
                  )
                  
                  # Add regressors to the model
                  for (regressor_col in selected_regressors) {
                    if (regressor_col %in% colnames(prophet_data)) {
                      m <- add_regressor(m, regressor_col)
                    }
                  }
                  
                  # Fit the model with data
                  fit.prophet(m, prophet_data)
                } else {
                  # Use original direct approach when no regressors
                  prophet(
                    prophet_data,
                    n.changepoints = n_changepoints_adjusted,
                    changepoint.prior.scale = changepoint_prior_item,  # Use item-specific value
                    seasonality.prior.scale = seasonality_prior_item,  # Use item-specific value
                    yearly.seasonality = input$yearly_seasonality,
                    weekly.seasonality = input$weekly_seasonality,
                    daily.seasonality = input$daily_seasonality,
                    interval.width = pred_interval_level
                  )
                }
              }, error = function(e) {
                warning(paste("Prophet model failed for", current_entity_name, ":", e$message))
                NULL
              })
              
              # ===== NEW: Store optimization info in model object =====
              if (!is.null(fit_model) && input$auto_optimize_prophet) {
                # Add optimization metadata to model for later reference
                fit_model$lucent_optimization <- list(
                  changepoint_prior_used = changepoint_prior_item,
                  seasonality_prior_used = seasonality_prior_item,
                  auto_optimized = TRUE,
                  optimization_timestamp = Sys.time()
                )
              }
              
              if (!is.null(fit_model)) {
                future <- make_future_dataframe(fit_model, periods = horizon, freq = prophet_freq_unit)
                
                # Add regressor values to future dataframe
                if (!is.null(selected_regressors) && length(selected_regressors) > 0) {
                  for (regressor_col in selected_regressors) {
                    if (regressor_col %in% colnames(prophet_data)) {
                      # Use the last known value of the regressor for future periods
                      last_value <- tail(prophet_data[[regressor_col]], 1)
                      if (length(last_value) > 0 && !is.na(last_value)) {
                        future[[regressor_col]] <- c(prophet_data[[regressor_col]], rep(last_value, horizon))
                      } else {
                        # If last value is NA, use mean of non-NA values
                        mean_value <- mean(prophet_data[[regressor_col]], na.rm = TRUE)
                        future[[regressor_col]] <- c(prophet_data[[regressor_col]], rep(ifelse(is.na(mean_value), 0, mean_value), horizon))
                      }
                    }
                  }
                }
                
                forecast_raw <- tryCatch({
                  predict(fit_model, future)
                }, error = function(e) {
                  warning(paste("Prophet forecast failed for", current_entity_name, ":", e$message))
                  NULL
                })
              }
              
              if (is.null(forecast_raw)) {
                warning(paste("Failed to generate Prophet forecast for", current_entity_name))
                next # Skip to next item
              }
            }
            
            # Enhanced progress message that shows parameter optimization
            if (input$method == "Prophet" && input$auto_optimize_prophet && input$batch_forecast) {
              incProgress(progress_per_item * 0.2, detail = paste("Optimizing parameters for:", current_entity_name))
              incProgress(progress_per_item * 0.2, detail = paste("Fitting model for:", current_entity_name))
            } else {
              incProgress(progress_per_item * 0.4, detail = paste("Fitting model for:", current_entity_name))
            }
            
            # --- Process Forecast Output ---
            if (!is.null(fit_model) && !is.null(forecast_raw)) {
              if (input$method == "Prophet") {
                # Extract from prophet dataframe
                forecast_output <- list(
                  mean = tail(forecast_raw$yhat, horizon),
                  lower = tail(forecast_raw$yhat_lower, horizon),
                  upper = tail(forecast_raw$yhat_upper, horizon),
                  fitted = forecast_raw$yhat[1:(nrow(forecast_raw)-horizon)],
                  residuals = fit_model$history$y - forecast_raw$yhat[1:nrow(fit_model$history)],
                  prophet_fcst_df = forecast_raw
                )
              } else {
                # Extract from forecast object (ARIMA/ETS)
                forecast_output <- list(
                  mean = as.numeric(forecast_raw$mean),
                  lower = as.numeric(forecast_raw$lower[, 1]),
                  upper = as.numeric(forecast_raw$upper[, 1]),
                  fitted = as.numeric(fitted(fit_model)),
                  residuals = as.numeric(residuals(fit_model))
                )
              }
              
              # --- Store Model and Metrics ---
              model_objects_list[[current_entity_name]] <- list(model = fit_model, method = input$method, forecast_output = forecast_output)
              
              # Calculate performance metrics using fitted vs actuals
              actuals_insample <- entity_data$Volume
              fitted_values <- forecast_output$fitted
              
              # Align actuals and fitted
              min_len <- min(length(actuals_insample), length(fitted_values))
              if (length(actuals_insample) > min_len) actuals_insample <- tail(actuals_insample, min_len)
              if (length(fitted_values) > min_len) fitted_values <- tail(fitted_values, min_len)
              
              if(length(actuals_insample) > 0 && length(actuals_insample) == length(fitted_values)){
                performance_metrics_list[[current_entity_name]] <- calculate_metrics(actuals_insample, fitted_values)
              } else {
                warning(paste("Could not align actuals and fitted for metrics calculation on", current_entity_name))
                performance_metrics_list[[current_entity_name]] <- list(MAE = NA, RMSE = NA, MAPE = NA)
              }
              
              # --- Store Formatted Forecast Results ---
              last_date <- max(entity_data$Date)
              
              # Generate forecast dates based on frequency
              forecast_dates <- NULL
              if (prophet_freq_unit == "day") {
                forecast_dates <- seq.Date(from = last_date + 1, by = "day", length.out = horizon)
              } else if (prophet_freq_unit == "week") {
                forecast_dates <- seq.Date(from = floor_date(last_date, "week") + weeks(1), by = "week", length.out = horizon)
              } else if (prophet_freq_unit == "month") {
                forecast_dates <- seq.Date(from = floor_date(last_date, "month") %m+% months(1), by = "month", length.out = horizon)
              } else if (prophet_freq_unit == "quarter") {
                forecast_dates <- seq.Date(from = floor_date(last_date, "quarter") %m+% months(3), by = "quarter", length.out = horizon)
              } else if (prophet_freq_unit == "year") {
                forecast_dates <- seq.Date(from = floor_date(last_date, "year") %m+% years(1), by = "year", length.out = horizon)
              } else {
                # Default to daily
                forecast_dates <- seq.Date(from = last_date + 1, by = "day", length.out = horizon)
              }
              
              item_forecast_df <- data.frame(
                Date = forecast_dates,
                Forecast = forecast_output$mean,
                Lower = forecast_output$lower,
                Upper = forecast_output$upper,
                Entity_ID = unique(entity_data$Entity_ID),
                Entity_Name = current_entity_name,
                Method = input$method
              )
              forecast_results_list[[current_entity_name]] <- item_forecast_df
              
              # --- Cross-Validation (if enabled) ---
              if (input$enable_cv) {
                # Implement cross-validation logic here if needed
                # This would be handled in a separate function
              }
              
            } else {
              warning(paste("Model fitting or forecasting failed for", current_entity_name))
            }
            
          }, error = function(e_item) { # Catch errors for the current item
            warning(paste("Error processing item", current_entity_name, ":", e_item$message))
            # Ensure failed items don't stop the whole batch
          })
          
          incProgress(progress_per_item * 0.2, detail = paste("Completed forecast for:", current_entity_name))
          
        } # End loop through items
        
        incProgress(0.95, detail = "Finalizing...")
        
        # --- Update Reactive Values with Results ---
        if (length(forecast_results_list) > 0) {
          rv$forecast_results <- bind_rows(forecast_results_list)
          rv$performance_metrics <- performance_metrics_list
          rv$model_objects <- model_objects_list
          rv$forecast_generated <- TRUE
          
          # --- Update UI Elements ---
          # Update result selectors with successfully forecasted items
          results_choices <- sort(names(rv$model_objects))
          results_selected <- if (!input$batch_forecast && input$forecast_entity %in% results_choices) {
            input$forecast_entity # Keep selection if single forecast was successful
          } else if (length(results_choices) > 0) {
            results_choices[1] # Select first available if batch or single failed
          } else {
            character(0) # No successful forecasts
          }
          
          tryCatch({updateSelectizeInput(session, "results_entity", choices = results_choices, selected = results_selected)}, error=function(e){})
          tryCatch({updateSelectizeInput(session, "diagnostics_entity", choices = results_choices, selected = results_selected)}, error=function(e){})
          
          showNotification(paste("Forecast completed for", length(results_choices), "items."), type = "message", duration = 5)
          
          # --- Switch to Results Tab ---
          updateNavbarPage(session, "main_nav", selected = "results")
          
        } else {
          showNotification("Forecast process completed, but no successful forecasts were generated.", type = "warning", duration = 5)
          rv$forecast_generated <- FALSE # Ensure flag is FALSE if nothing was generated
        }
        
      }, error = function(e) { # Catch errors in the overall process setup
        showNotification(paste("Forecast Error:", e$message), type = "error", duration = 5)
        rv$forecast_generated <- FALSE # Ensure flag is reset on error
      }, warning = function(w) { # Display warnings from the item loop
        showNotification(paste("Forecast Warning:", w$message), type = "warning", duration = 5)
      })
    }) # End withProgress
  }) # End observeEvent(input$go)
  
  
  
  # ===== RESULTS TAB LOGIC =====
  
  # ===== Helper function to get frequency details (Results Tab) =====
  get_current_frequency_results <- reactive({ # Renamed slightly to avoid clash if needed, though scope should prevent it
    req(rv$processed_data, input$results_entity)
    current_entity_name <- input$results_entity
    entity_data <- tryCatch({
      rv$processed_data %>% filter(Entity_Name == current_entity_name) %>% arrange(Date)
    }, error = function(e) { NULL })
    if (is.null(entity_data) || nrow(entity_data) < 2) {
      return(list(freq_numeric = 1, freq_unit = "day"))
    }
    detect_frequency(entity_data$Date) # Use the same detect_frequency helper
  })
  
  # ===== Sync item selection across tabs =====
  # Keep this logic as input$results_entity exists here
  observeEvent(input$results_entity, {
    req(input$results_entity)
    current_selection <- input$results_entity
    # Prevent infinite loops if updateSelectizeInput triggers this observeEvent again
    if (is.null(rv$current_entity) || current_selection != rv$current_entity) {
      rv$current_entity <- current_selection
      # Update others if they exist and differ
      tryCatch({ if (!is.null(input$selectentity) && input$selectentity != current_selection) updateSelectizeInput(session, "selectentity", selected = current_selection) }, error = function(e) {})
      tryCatch({ if (!is.null(input$forecast_entity) && input$forecast_entity != current_selection) updateSelectizeInput(session, "forecast_entity", selected = current_selection) }, error = function(e) {})
      tryCatch({ if (!is.null(input$diagnostics_entity) && input$diagnostics_entity != current_selection) updateSelectizeInput(session, "diagnostics_entity", selected = current_selection) }, error = function(e) {})
    }
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  
  # Keep other sync observers for robustness - NOTE: removed duplicate selectentity observer to avoid conflicts
  observeEvent(input$forecast_entity, {
    req(input$forecast_entity)
    current_selection <- input$forecast_entity
    if (!is.null(rv$current_entity) && current_selection != rv$current_entity) {
      rv$current_entity <- current_selection
      tryCatch({ if (!is.null(input$selectentity) && input$selectentity != current_selection) updateSelectizeInput(session, "selectentity", selected = current_selection) }, error = function(e) {})
      tryCatch({ if (!is.null(input$results_entity) && input$results_entity != current_selection) updateSelectizeInput(session, "results_entity", selected = current_selection) }, error = function(e) {})
      tryCatch({ if (!is.null(input$diagnostics_entity) && input$diagnostics_entity != current_selection) updateSelectizeInput(session, "diagnostics_entity", selected = current_selection) }, error = function(e) {})
    }
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  observeEvent(input$diagnostics_entity, {
    req(input$diagnostics_entity)
    current_selection <- input$diagnostics_entity
    if (!is.null(rv$current_entity) && current_selection != rv$current_entity) {
      rv$current_entity <- current_selection
      tryCatch({ if (!is.null(input$selectentity) && input$selectentity != current_selection) updateSelectizeInput(session, "selectentity", selected = current_selection) }, error = function(e) {})
      tryCatch({ if (!is.null(input$forecast_entity) && input$forecast_entity != current_selection) updateSelectizeInput(session, "forecast_entity", selected = current_selection) }, error = function(e) {})
      tryCatch({ if (!is.null(input$results_entity) && input$results_entity != current_selection) updateSelectizeInput(session, "results_entity", selected = current_selection) }, error = function(e) {})
    }
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  
  # ===== Performance Metrics Boxes =====
  # (Keep original code for mae_box, rmse_box, mape_box)
  output$mae_box <- renderUI({
    req(rv$forecast_generated, input$results_entity) # Ensure forecast ran and an item is selected
    metrics <- rv$performance_metrics[[input$results_entity]]
    val <- if (!is.null(metrics) && !is.na(metrics$MAE)) metrics$MAE else "N/A"
    div(class = "status-box status-box-yellow", icon("arrows-alt-h"), h4(val), p("Mean Absolute Error (MAE)")) # Changed icon
  })
  
  output$rmse_box <- renderUI({
    req(rv$forecast_generated, input$results_entity)
    metrics <- rv$performance_metrics[[input$results_entity]]
    val <- if (!is.null(metrics) && !is.na(metrics$RMSE)) metrics$RMSE else "N/A"
    div(class = "status-box status-box-orange", icon("square-root-alt"), h4(val), p("Root Mean Square Error (RMSE)")) # Changed icon
  })
  
  output$mape_box <- renderUI({
    req(rv$forecast_generated, input$results_entity)
    metrics <- rv$performance_metrics[[input$results_entity]]
    val <- if (!is.null(metrics) && !is.na(metrics$MAPE)) paste0(round(metrics$MAPE, 2), "%") else "N/A"
    div(class = "status-box status-box-red", icon("percent"), h4(val), p("Mean Abs. Pct. Error (MAPE)"))
  })
  
  
  # ===== Results Plot (Corrected Marker Logic) =====
  output$results_plot <- renderPlotly({
    req(rv$forecast_generated, input$results_entity, rv$processed_data, rv$forecast_results)
    
    item_hist_data <- rv$processed_data %>% filter(Entity_Name == input$results_entity) %>% arrange(Date)
    item_fcst_data <- rv$forecast_results %>% filter(Entity_Name == input$results_entity) %>% arrange(Date)
    
    if (nrow(item_hist_data) == 0 || nrow(item_fcst_data) == 0) {
      return(plot_ly() %>% layout(title = paste("Data or Forecast not found for:", input$results_entity)))
    }
    
    last_hist_date = max(item_hist_data$Date)
    first_fcst_date = min(item_fcst_data$Date)
    last_fcst_date = max(item_fcst_data$Date)
    min_date_plot <- max(min(item_hist_data$Date), last_hist_date - years(3))
    
    p <- plot_ly() %>%
      add_trace(data = item_hist_data, x = ~Date, y = ~Volume, type = 'scatter', mode = 'lines',
                line = list(color = '#3c8dbc'), name = 'Historical')
    
    # Determine plot mode and fill
    plot_mode <- if (input$results_plot_type == "Line with Points") 'lines+markers' else 'lines'
    plot_fill <- if (input$results_plot_type == "Area") 'tonexty' else 'none'
    
    # *** CORRECTED: Conditionally define marker argument ***
    marker_arg <- NULL
    if (plot_mode == 'lines+markers') {
      marker_arg <- list(color = '#00a65a', size = 4)
    }
    
    p <- p %>% add_trace(
      data = item_fcst_data, x = ~Date, y = ~Forecast, type = 'scatter', mode = plot_mode,
      fill = plot_fill, fillcolor = 'rgba(0, 166, 90, 0.1)',
      line = list(color = '#00a65a', dash = 'dash'),
      marker = marker_arg, # Use the conditional argument
      name = 'Forecast'
    )
    
    # Prediction Intervals (Keep original logic)
    if (input$show_intervals && "Lower" %in% colnames(item_fcst_data) && "Upper" %in% colnames(item_fcst_data)) {
      item_fcst_data <- item_fcst_data %>% mutate(Lower = as.numeric(Lower), Upper = as.numeric(Upper)) %>% filter(!is.na(Lower), !is.na(Upper))
      if(nrow(item_fcst_data) > 0){
        conf_level <- rv$model_objects[[input$results_entity]]$model$level[1] %||% 80
        interval_name <- paste0(conf_level, "% Interval")
        p <- p %>% add_trace(
          data = item_fcst_data,
          x = ~c(Date, rev(Date)),
          y = ~c(Lower, rev(Upper)),
          type = 'scatter', mode = 'lines',
          fill = 'toself', fillcolor = 'rgba(0, 166, 90, 0.2)',
          line = list(color = 'transparent'),
          showlegend = TRUE,
          name = interval_name
        )
      }
    }
    
    # Layout (Keep original logic)
    p %>% layout(
      title = enc2utf8(paste("Forecast Results for", input$results_entity)),
      xaxis = list(title = "Date", range = c(min_date_plot, last_fcst_date), rangeslider = list(visible=TRUE)),
      yaxis = list(title = "Volume"),
      hovermode = "x unified",
      legend = list(orientation = "h", xanchor = "center", x = 0.5, y = -0.2)
    )
  })
  
  # ===== Results Table (Corrected Mutate Logic) =====
  output$results_table <- renderDT({
    req(rv$forecast_generated, input$results_entity, rv$processed_data, rv$forecast_results)
    
    # Prepare Historical Data Part
    item_hist_data <- rv$processed_data %>%
      filter(Entity_Name == input$results_entity) %>%
      select(Date, Volume, Entity_ID, Entity_Name) %>%
      mutate(Type = "Historical") %>%
      rename(Value = Volume) # Keep 'Value' for combining
    
    # Prepare Forecast Data Part
    item_fcst_data_prep <- rv$forecast_results %>%
      filter(Entity_Name == input$results_entity) %>%
      mutate(Type = "Forecast") %>%
      rename(Value = Forecast) # Keep 'Value' for combining
    
    # Combine based on selected view
    display_data <- switch(
      input$table_view,
      "Forecast Only" = item_fcst_data_prep %>% select(Date, Entity_ID, Entity_Name, Type, Value, Lower, Upper),
      # Ensure consistent columns
      "Historical + Forecast" = bind_rows(
        item_hist_data %>% mutate(Lower = NA_real_, Upper = NA_real_),
        # Add NA intervals to hist
        item_fcst_data_prep %>% select(Date, Entity_ID, Entity_Name, Type, Value, Lower, Upper)
      ) %>% arrange(Date),
      "Full Data" = bind_rows(
        item_hist_data %>% mutate(Lower = NA_real_, Upper = NA_real_),
        item_fcst_data_prep %>% select(Date, Entity_ID, Entity_Name, Type, Value, Lower, Upper)
      ) %>% arrange(Date),
      item_fcst_data_prep %>% select(Date, Entity_ID, Entity_Name, Type, Value, Lower, Upper) # Default
    )
    
    
    # *** CORRECTED: Format for display ***
    display_data_formatted <- display_data %>%
      # Create the conditional columns FIRST using the original 'Value'
      mutate(
        Historical = ifelse(Type == "Historical", Value, NA_real_),
        Forecast = ifelse(Type == "Forecast", Value, NA_real_),
        Date = format(Date, "%Y-%m-%d") # Format date
      ) %>%
      # NOW select the final columns in the desired order
      select(Date, Type, Entity_Name, Historical, Forecast, Lower, Upper) %>%
      # Apply rounding at the end - handle NA values properly
      mutate(across(where(is.numeric), ~ if_else(is.na(.), ., round(., 2))))
    

    
    # Determine visibility of interval columns based on view (optional refinement)
    intervals_visible <- TRUE # Default to show
    # Example: if (input$table_view == "Historical Only") intervals_visible <- FALSE
    # Or base it on input$show_intervals checkbox if you add one for the table
    
    datatable(
      display_data_formatted,
      options = list(pageLength = 15, scrollX = TRUE, autoWidth = TRUE, searching = TRUE,
                     # Example conditional column visibility
                     columnDefs = list(list(targets = c("Lower", "Upper"), visible = intervals_visible))
      ),
      rownames = FALSE,
      filter = 'top',
      class = 'cell-border stripe compact hover',
      caption = paste("Data View:", input$table_view, "for", input$results_entity)
    )
  })
  
  # ===== Forecast Statistics =====
  # (Keep original code)
  output$forecast_stats <- renderPrint({
    req(rv$forecast_generated, input$results_entity, rv$model_objects)
    model_info <- rv$model_objects[[input$results_entity]]
    metrics <- rv$performance_metrics[[input$results_entity]]
    
    if (is.null(model_info)) return(cat("Model information not available."))
    
    cat("===== Forecast Summary Statistics =====")
    cat("\nItem:", input$results_entity)
    cat("\nMethod:", model_info$method)
    fc_horizon <- nrow(rv$forecast_results %>% filter(Entity_Name == input$results_entity)) # Calculate horizon
    cat("\nForecast Horizon:", fc_horizon)
    
    
    cat("\n\n--- In-Sample Performance ---")
    if (!is.null(metrics)) {
      # Use %||% from rlang if available for cleaner NA handling, otherwise base R
      mae_val <- metrics$MAE ; if(is.null(mae_val) || is.na(mae_val)) mae_val <- "NA"
      rmse_val <- metrics$RMSE; if(is.null(rmse_val) || is.na(rmse_val)) rmse_val <- "NA"
      mape_val <- metrics$MAPE; if(is.null(mape_val) || is.na(mape_val)) mape_val <- "NA" else mape_val <- paste0(mape_val, "%")
      
      cat("\n MAE: ", mae_val)
      cat("\n RMSE:", rmse_val)
      cat("\n MAPE:", mape_val)
    } else {
      cat("\n No in-sample metrics calculated.")
    }
    
    # Include accuracy() summary if forecast pkg model
    if (inherits(model_info$model, c("ARIMA", "ets", "forecast"))) {
      cat("\n\n--- forecast::accuracy() ---")
      tryCatch({
        print(accuracy(model_info$model)) # Prints training set accuracy
      }, error = function(e){ cat("\n Error getting accuracy():", e$message)})
    }
    
    # Add forecast summary stats if available in forecast_output
    fc_output <- model_info$forecast_output
    if(!is.null(fc_output) && !is.null(fc_output$mean)){
      cat("\n\n--- Forecast Values Summary ---")
      print(summary(fc_output$mean))
      if(!is.null(fc_output$lower) && !is.null(fc_output$upper)){
        avg_width <- tryCatch(mean(fc_output$upper - fc_output$lower, na.rm=TRUE), error = function(e) NA)
        cat("\n Avg. Interval Width:", if(!is.na(avg_width)) round(avg_width, 2) else "NA")
      }
    }
  })
  
  
  # ===== Decomposition Plot =====
  # (Keep original code - uses get_current_frequency_results)
  output$decomposition_plot <- renderPlotly({
    req(rv$forecast_generated, input$results_entity, rv$model_objects, rv$processed_data)
    model_info <- rv$model_objects[[input$results_entity]]
    
    if (is.null(model_info)) return(plot_ly() %>% layout(title = "Model not available"))
    
    entity_data <- rv$processed_data %>% filter(Entity_Name == input$results_entity) %>% arrange(Date)
    if(nrow(entity_data) == 0) return(plot_ly() %>% layout(title = "Historical data not found"))
    
    tryCatch({
      if (model_info$method == "Prophet") {
        # Prophet code remains unchanged...
        
      } else {
        # Use STL decomposition for ARIMA/ETS
        freq_details <- get_current_frequency_results()
        ts_freq <- freq_details$freq_numeric
        
        if (ts_freq <= 1) return(plot_ly() %>% layout(title = "Decomposition requires frequency > 1"))
        
        ts_data <- ts(entity_data$Volume, frequency = ts_freq)
        # Check data length for STL
        if (sum(!is.na(ts_data)) < 2 * ts_freq + 1) {
          return(plot_ly() %>% layout(title = "Need > 2 periods of non-NA data for STL decomposition"))
        }
        
        # Perform STL decomposition
        decomp_stl <- stl(ts_data, s.window = "periodic", na.action = na.omit)
        
        # Manual extraction of STL components
        stl_time <- time(ts_data)
        data_component <- as.numeric(ts_data)
        trend_component <- as.numeric(decomp_stl$time.series[, "trend"])
        seasonal_component <- as.numeric(decomp_stl$time.series[, "seasonal"]) 
        remainder_component <- as.numeric(decomp_stl$time.series[, "remainder"])
        
        # Create our own long-format data frame for plotting
        decomp_df <- data.frame(
          time = rep(stl_time, 4),
          value = c(data_component, trend_component, seasonal_component, remainder_component),
          component = factor(rep(c("Data", "Trend", "Seasonal", "Remainder"), each = length(stl_time)),
                             levels = c("Data", "Trend", "Seasonal", "Remainder"))
        )
        
        # Add Date column
        non_na_indices <- which(!is.na(entity_data$Volume))
        non_na_dates <- entity_data$Date[non_na_indices]
        
        # Ensure lengths match before mapping dates
        if(length(stl_time) == length(non_na_dates)) {
          decomp_df$Date <- rep(non_na_dates, 4)
          x_var <- ~Date
          x_title <- "Date"
        } else {
          # If lengths don't match, use time index
          x_var <- ~time
          x_title <- "Time Index"
        }
        
        # Create a list to hold individual plots
        plot_list <- list()
        
        # Define colors for components
        colors <- c("Data" = "gray", "Trend" = "#00a65a", "Seasonal" = "#f39c12", "Remainder" = "#dd4b39")
        
        # Create individual component plots
        components <- levels(decomp_df$component)
        for(i in 1:length(components)) {
          comp <- components[i]
          comp_data <- decomp_df %>% filter(component == comp)
          
          # Create a plot for this component
          p <- plot_ly(data = comp_data, x = x_var, y = ~value, 
                       type = 'scatter', mode = 'lines',
                       line = list(color = colors[comp], width = 2),
                       name = comp) %>%
            layout(
              showlegend = (i == 1),  # Only show legend for first plot
              xaxis = list(title = if(i == length(components)) x_title else ""),  # Only add x-axis title to bottom plot
              yaxis = list(title = comp),
              margin = list(l = 50, r = 20, t = 10, b = if(i == length(components)) 40 else 0)
            )
          
          plot_list[[i]] <- p
        }
        
        # Combine plots vertically with subplot
        fig <- subplot(
          plot_list,
          nrows = length(components),
          shareX = TRUE,
          titleY = TRUE
        ) %>% 
          layout(
            title = paste("STL Decomposition for", input$results_entity),
            showlegend = TRUE,
            legend = list(orientation = "h", xanchor = "center", x = 0.5, y = 1.05),
            margin = list(t = 50)
          )
        
        return(fig)
      }
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error creating decomposition plot:", e$message))
    })
  })
  
  
  # ===== Model Summary =====
  # (Keep original code)
  output$model_summary <- renderPrint({
    req(rv$forecast_generated, input$results_entity, rv$model_objects)
    model_info <- rv$model_objects[[input$results_entity]]
    
    if (is.null(model_info)) return(cat("No model information available for this item."))
    
    cat("===== Model Summary =====\n")
    cat("Item:", input$results_entity, "\n")
    cat("Method:", model_info$method, "\n\n")
    
    tryCatch({
      model_obj <- model_info$model
      if (inherits(model_obj, c("ARIMA", "ets", "Arima"))) { # Check class using inherits
        # Standard summary for forecast package models
        print(summary(model_obj))
      } else if (inherits(model_obj, "prophet")) {
        # Custom summary for Prophet
        cat("Prophet Model Parameters:\n")
        cat("- Growth:", model_obj$growth, "\n")
        cat("- Changepoint Prior Scale:", model_obj$changepoint.prior.scale, "\n")
        cat("- Seasonality Prior Scale:", model_obj$seasonality.prior.scale, "\n")
        # Handle potential differences in Prophet versions for seasonality attributes
        cat("- Yearly Seasonality:", model_obj$yearly.seasonality %||% "NA", "\n") # Use %||% for safety
        cat("- Weekly Seasonality:", model_obj$weekly.seasonality %||% "NA", "\n")
        cat("- Daily Seasonality:", model_obj$daily.seasonality %||% "NA", "\n")
        if (!is.null(model_obj$holidays)) {
          holiday_info <- if (!is.null(model_obj$country_holidays)) model_obj$country_holidays else "Custom"
          cat("- Holidays Included:", holiday_info, "\n")
          cat("- Holiday Prior Scale:", model_obj$holidays.prior.scale %||% "NA", "\n")
        }
        # Safely check for changepoints
        cps_df <- tryCatch(model_obj$changepoints, error = function(e) NULL)
        if (!is.null(cps_df) && inherits(cps_df, "data.frame")) {
          cat("- Number of Changepoints:", nrow(cps_df), "\n")
        } else if (!is.null(model_obj$n.changepoints)) {
          cat("- Configured N Changepoints:", model_obj$n.changepoints, "\n")
        }
        
      } else {
        cat("Model summary format not recognized for this object type.\n")
        # Attempt generic print if summary fails
        print(model_obj)
      }
    }, error = function(e) {
      cat("Error displaying model summary:", e$message, "\n")
      cat("--- Raw Model Object --- \n")
      tryPrint(model_info$model) # Try to print the raw object on error
    })
  })
  
  # ===== Cross-Validation Results =====
  # (Keep original code - relies on rv$comparison_metrics being set elsewhere if CV ran)
  output$cv_results <- renderDT({
    # This ideally depends on rv$comparison_metrics being populated,
    # either from Forecast Tab CV or Diagnostics Tab comparison.
    # Let's assume rv$comparison_metrics holds the relevant data if CV was run.
    req(input$enable_cv) # Only render if CV was enabled
    req(rv$comparison_metrics) # Need the CV results data
    
    cv_data_item <- rv$comparison_metrics # Assumes it's already filtered or just for one item
    
    if (is.null(cv_data_item) || nrow(cv_data_item) == 0) {
      # Return a datatable with a message, avoiding NULL
      return(datatable(data.frame(Status = "No Cross-Validation results available for this item/run."),
                       options = list(dom = 't'), rownames = FALSE,
                       caption = "Cross-Validation Performance Metrics"))
    }
    
    # Ensure columns exist before formatting
    cols_to_format <- intersect(c('MAE', 'RMSE', 'MAPE'), names(cv_data_item))
    
    datatable(
      cv_data_item,
      options = list(dom = 't', pageLength = -1, searching=FALSE), # Simple table display
      rownames = FALSE,
      caption = "Cross-Validation Performance Metrics"
    ) %>% formatRound(cols_to_format, digits = 4)
    
  })
  
  # Render CV Plot (Placeholder - keep original)
  output$cv_plot <- renderPlotly({
    req(input$enable_cv)
    plot_ly() %>% layout(title = "CV Error Plot (Data N/A)")
  })
  
  
  # ===== Other Results Tab Actions =====
  # (Keep original code)
  observeEvent(input$rerun_forecast, {
    # Navigate back to the Forecast tab
    # Make sure the navbarPage UI has an ID, e.g., id = "main_nav"
    updateNavbarPage(session, "main_nav", selected = "forecast")
    showNotification("Adjust settings and click 'Run Forecast' again.", type = "info")
  })
  
  observeEvent(input$compare_models, {
    # Navigate to the Diagnostics tab
    # Assumes Diagnostics tab has value="diagnostics" and navbarPage has id = "main_nav"
    updateNavbarPage(session, "main_nav", selected = "diagnostics")
    showNotification("Select models to compare and click 'Run Comparison'.", type = "info")
  })
  
  # Action Button: Export Report (Placeholder - keep original)
  observeEvent(input$export_report, {
    showModal(modalDialog(
      title = "Export Report",
      "Generating a full PDF/Word report typically requires an R Markdown template.",
      "For now, you can download the forecast data using the 'Download Results' button and format.",
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })
  
  
  # ===== Download Results =====
  # (Keep original code)
  output$download <- downloadHandler(
    filename = function() {
      req(input$results_entity) # Need an item selected
      entity_name_clean <- gsub("[^A-Za-z0-9_]", "_", input$results_entity)
      # Try to get method name safely
      method_name <- tryCatch(rv$model_objects[[input$results_entity]]$method, error=function(e) "model") %||% "model"
      
      paste0("forecast_", entity_name_clean, "_", method_name, "_", Sys.Date(), ".", input$export_format)
    },
    content = function(file) {
      req(rv$forecast_generated, input$results_entity, rv$processed_data, rv$forecast_results)
      
      # Prepare data for export
      item_hist <- rv$processed_data %>%
        filter(Entity_Name == input$results_entity) %>%
        select(Date, Volume, Entity_ID, Entity_Name) %>%
        mutate(Type = "Historical")
      
      item_fcst <- rv$forecast_results %>%
        filter(Entity_Name == input$results_entity) %>%
        mutate(Type = "Forecast")
      
      # Combine Historical and Forecast
      export_df <- bind_rows(
        item_hist %>% rename(Value = Volume) %>% mutate(Lower=NA, Upper=NA), # Add NA interval cols
        item_fcst %>% rename(Value = Forecast) %>% select(-any_of("Method")) # Remove Method col if present using any_of
      ) %>%
        select(Date, Entity_ID, Entity_Name, Type, Value, Lower, Upper) %>% # Select desired columns
        arrange(Entity_ID, Date) # Sort
      
      tryCatch({
        if (input$export_format == "xlsx") {
          # Create list for multiple sheets
          sheets <- list("Forecast_Data" = export_df)
          # Add metrics sheet if available
          if (!is.null(rv$performance_metrics[[input$results_entity]])) {
            metrics_df <- as.data.frame(t(rv$performance_metrics[[input$results_entity]])) # Transpose for better view?
            colnames(metrics_df) <- names(rv$performance_metrics[[input$results_entity]])
            metrics_df$Item <- input$results_entity # Add item name
            metrics_df <- metrics_df %>% select(Item, everything()) # Item first
            sheets[["Metrics"]] <- metrics_df
          }
          # Add model summary sheet? Capture output?
          # model_summary_text <- capture.output(print(summary(rv$model_objects[[input$results_entity]]$model))) # Example
          # sheets[["Model_Summary"]] <- data.frame(Summary = model_summary_text)
          
          write_xlsx(sheets, file)
          
        } else if (input$export_format == "csv") {
          # CSV only exports the main data table
          write.csv(export_df, file, row.names = FALSE, na = "")
        } else if (input$export_format == "rds") {
          # Save relevant R objects in a list
          save_list <- list(
            historical_data = item_hist,
            forecast_data = item_fcst,
            model_info = rv$model_objects[[input$results_entity]],
            metrics = rv$performance_metrics[[input$results_entity]],
            export_timestamp = Sys.time()
          )
          saveRDS(save_list, file)
        }
      }, error = function(e) {
        showNotification(paste("Error during download:", e$message), type = "error")
      })
    }
  )
  
  # ===== Download All Entities Results =====
  output$download_all_entities <- downloadHandler(
    filename = function() {
      # Generate filename based on export format
      format_ext <- input$export_format %||% "xlsx"
      paste0("forecast_all_entities_", Sys.Date(), ".", format_ext)
    },
    content = function(file) {
      req(rv$forecast_generated, rv$processed_data, rv$forecast_results)
      
      # Get all unique items that have forecast results
      forecasted_items <- unique(rv$forecast_results$Entity_Name)
      
      if (length(forecasted_items) == 0) {
        showNotification("No forecast results available for download.", type = "warning")
        return()
      }
      
      # Prepare combined data for all items
      all_hist_data <- rv$processed_data %>%
        filter(Entity_Name %in% forecasted_items) %>%
        select(Date, Volume, Entity_ID, Entity_Name) %>%
        mutate(Type = "Historical") %>%
        rename(Value = Volume) %>%
        mutate(Lower = NA_real_, Upper = NA_real_)
      
      all_fcst_data <- rv$forecast_results %>%
        mutate(Type = "Forecast") %>%
        rename(Value = Forecast) %>%
        select(-any_of("Method"))
      
      # Combine all historical and forecast data
      export_df_all <- bind_rows(all_hist_data, all_fcst_data) %>%
        select(Date, Entity_ID, Entity_Name, Type, Value, Lower, Upper) %>%
        arrange(Entity_Name, Date)
      
      # Prepare metrics data for all items
      all_metrics <- data.frame()
      if (!is.null(rv$performance_metrics)) {
        metrics_list <- list()
        for (entity_name in forecasted_items) {
          if (!is.null(rv$performance_metrics[[entity_name]])) {
            metrics_row <- as.data.frame(rv$performance_metrics[[entity_name]])
            metrics_row$Entity_Name <- entity_name
            metrics_row$Method <- tryCatch(rv$model_objects[[entity_name]]$method, error = function(e) "Unknown")
            metrics_list[[entity_name]] <- metrics_row
          }
        }
        if (length(metrics_list) > 0) {
          all_metrics <- bind_rows(metrics_list) %>%
            select(Entity_Name, Method, everything())
        }
      }
      
      tryCatch({
        if (input$export_format == "xlsx") {
          # Create Excel file with multiple sheets
          sheets <- list(
            "All_Forecast_Data" = export_df_all,
            "Summary" = data.frame(
              Metric = c("Total Entities", "Forecast Generated", "Date Range", "Export Date"),
              Value = c(
                length(forecasted_items),
                format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                paste(format(min(export_df_all$Date), "%Y-%m-%d"), "to", format(max(export_df_all$Date), "%Y-%m-%d")),
                format(Sys.Date(), "%Y-%m-%d")
              )
            )
          )
          
          # Add metrics sheet if available
          if (nrow(all_metrics) > 0) {
            sheets[["All_Metrics"]] <- all_metrics
          }
          
          # Add individual item sheets
          for (entity_name in forecasted_items) {
            entity_data <- export_df_all %>% filter(Entity_Name == entity_name)
            sheet_name <- paste0("Item_", gsub("[^A-Za-z0-9_]", "_", entity_name))
            # Limit sheet name to 31 characters (Excel limit)
            if (nchar(sheet_name) > 31) {
              sheet_name <- substr(sheet_name, 1, 31)
            }
            sheets[[sheet_name]] <- entity_data
          }
          
          write_xlsx(sheets, file)
          
        } else if (input$export_format == "csv") {
          # CSV exports only the main combined data
          write.csv(export_df_all, file, row.names = FALSE, na = "")
          
        } else if (input$export_format == "rds") {
          # Save comprehensive R object with all data
          save_list <- list(
            all_historical_data = all_hist_data,
            all_forecast_data = all_fcst_data,
            combined_data = export_df_all,
            all_metrics = all_metrics,
            model_objects = rv$model_objects[forecasted_items],
            performance_metrics = rv$performance_metrics[forecasted_items],
            forecasted_items = forecasted_items,
            export_timestamp = Sys.time()
          )
          saveRDS(save_list, file)
        }
        
        showNotification(paste("Successfully downloaded results for", length(forecasted_items), "items"), type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error during download:", e$message), type = "error")
      })
    }
  )
  
  
  # Start of the Diagnostics Tab server code 
  
  
  
  # ===== Diagnostics Tab Server Logic =====
  
  # Update diagnostics_model choices when diagnostics_entity changes
  observe({
    req(input$diagnostics_entity, rv$model_objects)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    
    if (!is.null(model_info)) {
      # For now we only have one model per item, could extend for multiple models
      updateSelectInput(session, "diagnostics_model", 
                        choices = model_info$method, 
                        selected = model_info$method)
    }
  })
  
  # ===== Helper to get residuals =====
  get_residuals <- reactive({
    req(rv$forecast_generated, input$diagnostics_entity, rv$model_objects)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    if(is.null(model_info) || is.null(model_info$forecast_output)) return(NULL)
    
    residuals_val <- model_info$forecast_output$residuals
    # Ensure residuals are numeric and remove NAs
    residuals_val <- as.numeric(residuals_val)
    residuals_val <- residuals_val[!is.na(residuals_val) & is.finite(residuals_val)] # Also check finite
    if(length(residuals_val) == 0) return(NULL)
    return(residuals_val)
  })
  
  # ===== Helper to get dates corresponding to residuals =====
  get_residual_dates <- reactive({
    req(rv$processed_data, input$diagnostics_entity, rv$model_objects)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    if(is.null(model_info)) return(NULL)
    
    if (model_info$method == "Prophet") {
      # Prophet residuals align with the history dataframe in the model object
      if(!is.null(model_info$model$history)) {
        residuals_val <- model_info$forecast_output$residuals
        valid_indices <- !is.na(residuals_val)
        # Ensure history dates match length of valid residuals
        if(nrow(model_info$model$history) >= sum(valid_indices)) {
          return(as.Date(model_info$model$history$ds[valid_indices]))
        }
      }
    } else {
      # For ARIMA/ETS, residuals align with original data
      ts_data_orig <- ts(rv$processed_data$Volume[rv$processed_data$Entity_Name==input$diagnostics_entity],
                         frequency = get_current_frequency()$freq_numeric)
      residuals_val <- model_info$forecast_output$residuals
      fitted_vals <- model_info$forecast_output$fitted
      
      valid_indices_fitted <- !is.na(fitted_vals)
      original_dates <- rv$processed_data$Date[rv$processed_data$Entity_Name==input$diagnostics_entity]
      
      if(length(original_dates) >= length(valid_indices_fitted)) {
        return(original_dates[valid_indices_fitted])
      }
    }
    
    # Fallback if alignment fails
    warning("Could not accurately determine dates for residuals.")
    residuals_val <- get_residuals()
    item_dates <- rv$processed_data$Date[rv$processed_data$Entity_Name==input$diagnostics_entity]
    return(tail(item_dates, length(residuals_val))) # Best guess: last N dates
  })
  
  # ===== Residual Plot =====
  output$residual_plot <- renderPlotly({
    residuals_val <- get_residuals()
    residual_dates <- get_residual_dates()
    
    if (is.null(residuals_val) || is.null(residual_dates) || 
        length(residuals_val) == 0 || length(residuals_val) != length(residual_dates)) {
      return(plot_ly() %>% layout(title = "Residuals not available or date mismatch"))
    }
    
    residuals_df <- data.frame(Date = residual_dates, Residual = residuals_val) %>% arrange(Date)
    
    plot_type <- input$residual_plot_type
    p <- NULL # Initialize plot
    
    tryCatch({
      if (plot_type == "Time Series") {
        p <- plot_ly(data = residuals_df, x = ~Date, y = ~Residual, type = 'scatter', 
                     mode = 'lines+markers',
                     marker = list(size = 3, color = '#3c8dbc'), 
                     line = list(width = 1, color = '#3c8dbc'), 
                     name="Residual") %>%
          add_lines(x=~Date, y=0, 
                    line=list(color='gray', dash='dash'), 
                    showlegend=FALSE, inherit=FALSE, 
                    name="Zero line") %>%
          layout(title = "Residuals Over Time", 
                 xaxis = list(title = "Date"), 
                 yaxis = list(title = "Residual"), 
                 showlegend = TRUE)
        
      } else if (plot_type == "Histogram") {
        p <- plot_ly(x = ~residuals_val, type = 'histogram', 
                     nbinsx = 30, 
                     marker = list(color = '#3c8dbc'), 
                     name="Histogram") %>%
          layout(title = "Distribution of Residuals", 
                 xaxis = list(title = "Residual"), 
                 yaxis = list(title = "Frequency"), 
                 showlegend = FALSE)
        
      } else if (plot_type == "QQ Plot") {
        # Check for constant residuals which break qqnorm/lm
        if(length(unique(round(residuals_val, 6))) <= 1) {
          stop("Residuals are constant, cannot create Q-Q plot.")
        }
        
        qq <- qqnorm(residuals_val, plot.it = FALSE)
        qq_df <- data.frame(x = qq$x, y = qq$y)
        
        if(nrow(qq_df) < 2) {
          stop("Need at least 2 points for Q-Q plot.")
        }
        
        line_fit <- lm(y ~ x, data = qq_df)
        line_df <- data.frame(
          x = range(qq_df$x), 
          y = predict(line_fit, newdata = data.frame(x = range(qq_df$x)))
        )
        
        p <- plot_ly() %>%
          add_trace(data = qq_df, x = ~x, y = ~y, 
                    type = 'scatter', mode = 'markers', 
                    marker = list(size = 5, color = '#3c8dbc'), 
                    name = 'Sample Quantiles') %>%
          add_trace(data = line_df, x = ~x, y = ~y, 
                    type = 'scatter', mode = 'lines', 
                    line = list(color = '#f39c12', width = 2), 
                    name = 'Reference Line') %>%
          layout(title = "Normal Q-Q Plot of Residuals", 
                 xaxis = list(title = "Theoretical Quantiles"), 
                 yaxis = list(title = "Sample Quantiles"), 
                 showlegend = TRUE)
        
      } else if (plot_type == "ACF") {
        if(length(residuals_val) < 3) {
          stop("Need at least 3 residuals for ACF plot.")
        }
        
        acf_values <- acf(residuals_val, plot = FALSE, 
                          na.action=na.pass, 
                          lag.max = min(30, length(residuals_val)-1))
        
        acf_df <- data.frame(Lag = acf_values$lag[-1], ACF = acf_values$acf[-1])
        n <- length(residuals_val)
        ci <- qnorm(0.975) / sqrt(n) # 95% CI
        
        p <- plot_ly() %>%
          add_trace(data = acf_df, x = ~Lag, y = ~ACF, 
                    type = 'bar', 
                    marker = list(color = '#3c8dbc'), 
                    name = 'ACF') %>%
          add_lines(x = range(acf_df$Lag), y = ci, 
                    line = list(color = '#f39c12', dash = 'dash'), 
                    showlegend=FALSE, inherit=FALSE, name="CI") %>%
          add_lines(x = range(acf_df$Lag), y = -ci, 
                    line = list(color = '#f39c12', dash = 'dash'), 
                    showlegend=FALSE, inherit=FALSE) %>%
          add_lines(x = range(acf_df$Lag), y = 0, 
                    line = list(color = 'gray'), 
                    showlegend=FALSE, inherit=FALSE) %>%
          layout(title = "Autocorrelation of Residuals", 
                 xaxis = list(title = "Lag"), 
                 yaxis = list(title = "Autocorrelation", range=c(-1,1)), 
                 showlegend = TRUE)
      }
      
      return(p)
    }, error = function(e) {
      return(plot_ly() %>% layout(title=paste("Error creating residual plot:", e$message)))
    })
  })
  
  # ===== Residual Statistics =====
  output$residual_stats <- renderPrint({
    residuals_val <- get_residuals()
    if (is.null(residuals_val)) {
      cat("Residuals not available.")
      return()
    }
    
    cat("===== Residual Statistics =====\n")
    cat("Number of Residuals:", length(residuals_val), "\n")
    print(summary(residuals_val)) # Includes Mean, Median, Min, Max, Quartiles
    cat("Standard deviation:", round(sd(residuals_val), 4), "\n")
    
    # Test for normality
    if(length(residuals_val) > 3 && 
       length(residuals_val) < 5000 && 
       length(unique(round(residuals_val,6))) > 1) {
      
      shapiro_test <- shapiro.test(residuals_val)
      cat("\nShapiro-Wilk Normality Test:\n")
      cat(" W =", round(shapiro_test$statistic, 4), 
          ", p-value =", format.pval(shapiro_test$p.value, digits = 4), "\n")
      cat(" Interpretation:", 
          ifelse(shapiro_test$p.value > 0.05, 
                 "Normal (fail to reject H0)", 
                 "Non-normal (reject H0)"), "\n")
    } else if (length(unique(round(residuals_val,6))) <= 1) {
      cat("\nShapiro-Wilk test not applicable (residuals are constant).\n")
    } else {
      cat("\nShapiro-Wilk test requires 3 < n < 5000 observations.\n")
    }
  })
  
  # ===== Residual Tests =====
  output$residual_tests <- renderPrint({
    residuals_val <- get_residuals()
    if (is.null(residuals_val) || length(residuals_val) < 5) {
      cat("Not enough residual data for tests.")
      return()
    }
    
    cat("===== Tests for Randomness in Residuals =====\n\n")
    
    # Ljung-Box test
    lb_lag <- min(10, length(residuals_val) %/% 5) # A common rule of thumb for lag
    if(lb_lag > 0) {
      tryCatch({
        lb_test <- Box.test(residuals_val, lag = lb_lag, type = "Ljung-Box")
        cat("Ljung-Box Test (Autocorrelation):\n")
        cat(" X-squared =", round(lb_test$statistic, 4), 
            ", df =", lb_test$parameter, 
            ", p-value =", format.pval(lb_test$p.value, digits = 4), "\n")
        cat(" Interpretation:", 
            ifelse(lb_test$p.value > 0.05, 
                   "No significant autocorrelation (good)", 
                   "Significant autocorrelation detected (problematic)"), "\n\n")
      }, error = function(e) {
        cat("Ljung-Box Test: Error -", e$message, "\n\n")
      })
    } else {
      cat("Ljung-Box Test: Not enough data for specified lag.\n\n")
    }
    
    # Breusch-Pagan Test for Heteroscedasticity (requires fitted values)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    fitted_vals <- model_info$forecast_output$fitted
    
    if (!is.null(fitted_vals)) {
      fitted_vals <- as.numeric(fitted_vals)
      # Align residuals and fitted, removing NAs pair-wise
      combined <- data.frame(
        res = residuals_val, 
        fit = fitted_vals[1:length(residuals_val)]
      ) %>% na.omit()
      
      if(nrow(combined) > 2 && 
         length(unique(round(combined$fit, 6))) > 1 && 
         length(unique(round(combined$res,6))) > 0) {
        
        tryCatch({
          bp_test <- lmtest::bptest(res ~ fit, data = combined)
          cat("Breusch-Pagan Test (Heteroscedasticity):\n")
          cat(" BP =", round(bp_test$statistic, 4), 
              ", df =", bp_test$parameter,
              ", p-value =", format.pval(bp_test$p.value, digits = 4), "\n")
          cat(" Interpretation:", 
              ifelse(bp_test$p.value > 0.05, 
                     "Homoscedasticity (constant variance - good)", 
                     "Heteroscedasticity (non-constant variance - problematic)"), "\n")
        }, error = function(e){
          cat("Breusch-Pagan Test: Error -", e$message, "\n")
        })
      } else {
        cat("Breusch-Pagan Test: Insufficient data or variation for test.\n")
      }
    } else {
      cat("Breusch-Pagan Test: Fitted values not available.\n")
    }
  })
  
  # ===== Model Parameters =====
  output$model_parameters <- renderPrint({
    req(rv$forecast_generated, input$diagnostics_entity, rv$model_objects)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    
    if (is.null(model_info)) {
      cat("No model information available for", input$diagnostics_entity)
      return()
    }
    
    cat("===== Model Parameters =====\n")
    cat("Item:", input$diagnostics_entity, "\n")
    cat("Method:", model_info$method, "\n\n")
    
    tryCatch({
      if (model_info$method == "ARIMA") {
        model_obj <- model_info$model
        cat("ARIMA Model Type:", paste0("ARIMA", arimaorder(model_obj)), "\n\n")
        
        if (!is.null(model_obj$coef) && length(model_obj$coef) > 0 && !is.null(model_obj$var.coef)) {
          cat("Coefficients:\n")
          var_diag <- tryCatch(diag(model_obj$var.coef), 
                               error=function(e) rep(NA, length(model_obj$coef)))
          std_errors <- sqrt(pmax(1e-9, var_diag))
          
          coef_table <- data.frame(
            Estimate = model_obj$coef,
            StdError = std_errors,
            row.names = names(model_obj$coef)
          )
          
          coef_table$t_value <- ifelse(!is.na(coef_table$StdError) & coef_table$StdError > 1e-9,
                                       coef_table$Estimate / coef_table$StdError, NA)
          df_resid <- length(model_obj$residuals) - length(model_obj$coef)
          coef_table$p_value <- ifelse(!is.na(coef_table$t_value) & df_resid > 0,
                                       2 * pt(abs(coef_table$t_value), df = df_resid, lower.tail = FALSE), NA)
          
          coef_table$significance <- cut(coef_table$p_value, 
                                         breaks=c(-Inf, 0.001, 0.01, 0.05, 0.1, Inf), 
                                         labels=c("***", "**", "*", ".", " "), 
                                         include.lowest=TRUE)
          
          print(format(coef_table, digits=4, nsmall=4))
          cat("\n---\nSignif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1\n\n")
        } else {
          cat("Coefficients or variance matrix not available or empty.\n\n")
        }
        
        cat("Information Criteria:\n")
        cat(" AIC:", round(model_obj$aic, 2), "\n")
        cat(" BIC:", round(BIC(model_obj), 2), "\n")
        cat(" Log Likelihood:", round(model_obj$loglik, 2), "\n\n")
        cat("Residual Variance (sigma^2):", round(model_obj$sigma2, 4), "\n")
        
      } else if (model_info$method == "Exponential Smoothing") {
        model_obj <- model_info$model
        cat("ETS Model:", model_obj$method, "\n\n")
        cat("Components:", paste(model_obj$components, collapse=", "), "\n\n")
        cat("Smoothing Parameters:\n", 
            paste0(" ", names(model_obj$par), ": ", round(model_obj$par, 4), collapse="\n"), "\n\n")
        cat("Initial States:\n", 
            paste0(" ", names(model_obj$initstate), ": ", round(model_obj$initstate, 4), collapse="\n"), "\n\n")
        cat("Information Criteria:\n")
        cat(" AIC:", round(model_obj$aic, 2), "\n")
        cat(" BIC:", round(model_obj$bic, 2), "\n")
        cat(" AICc:", round(model_obj$aicc, 2), "\n")
        cat(" Log Likelihood:", round(model_obj$loglik, 2), "\n")
        cat(" Sigma^2:", round(model_obj$sigma2, 4), "\n")
        
      } else if (model_info$method == "Prophet") {
        prophet_model <- model_info$model
        cat("Prophet Model Configuration:\n\n")
        cat("- Growth:", prophet_model$growth, "\n")
        cat("- Changepoint Prior Scale:", prophet_model$changepoint.prior.scale, "\n")
        cat("- Seasonality Prior Scale:", prophet_model$seasonality.prior.scale, "\n")
        
        cat("\nSeasonality Components:\n")
        active_seasonalities <- names(prophet_model$seasonalities)
        if (length(active_seasonalities) > 0) {
          for (s_name in active_seasonalities) {
            s_details <- prophet_model$seasonalities[[s_name]]
            cat(paste0("- ", s_name, ": period=", round(s_details$period,1), 
                       ", order=", s_details$fourier.order, 
                       ", mode=", s_details$mode, "\n"))
          }
        } else {
          cat("- None detected or specified\n")
        }
        
        # Show regressor information if available
        if (!is.null(prophet_model$regressors) && length(prophet_model$regressors) > 0) {
          cat("\nAdditional Regressors:\n")
          for (regressor_name in names(prophet_model$regressors)) {
            regressor_info <- prophet_model$regressors[[regressor_name]]
            cat(paste0("- ", regressor_name, ": mode=", regressor_info$mode, "\n"))
          }
          
          # Try to show regressor coefficients if available
          if (!is.null(prophet_model$params)) {
            regressor_coeffs <- prophet_model$params[grepl("beta_", names(prophet_model$params))]
            if (length(regressor_coeffs) > 0) {
              cat("\nRegressor Coefficients:\n")
              for (i in seq_along(regressor_coeffs)) {
                coeff_name <- names(regressor_coeffs)[i]
                coeff_value <- mean(regressor_coeffs[[i]], na.rm = TRUE)
                clean_name <- gsub("beta_", "", coeff_name)
                cat(paste0("- ", clean_name, ": ", round(coeff_value, 4), "\n"))
              }
            }
          }
        }
        
        if (!is.null(prophet_model$holidays)) {
          cat("\nHolidays:\n")
          cat("- Country/Source:", 
              ifelse(!is.null(prophet_model$country_holidays), 
                     prophet_model$country_holidays, "Custom"), "\n")
          cat("- Prior Scale:", prophet_model$holidays.prior.scale, "\n")
        }
        
        if (!is.null(prophet_model$changepoints)) {
          cat("\nTrend Changepoints:", length(prophet_model$changepoints), "detected\n")
        }
        
        # Component statistics (from stored forecast output)
        if (!is.null(model_info$forecast_output$prophet_fcst_df)) {
          forecast_df <- model_info$forecast_output$prophet_fcst_df
          cat("\nComponent Statistics (from forecast dataframe):\n")
          component_stats <- function(component_name) {
            if(component_name %in% names(forecast_df)) {
              vals <- forecast_df[[component_name]]
              range_val <- diff(range(vals, na.rm=TRUE))
              # Add check for constant component
              if(is.na(range_val) || range_val < 1e-6) return("Constant (or NA)")
              paste0("Mean=", round(mean(vals, na.rm=TRUE),2),
                     ", StdDev=", round(sd(vals, na.rm=TRUE),2),
                     ", Range=", round(range_val,2) )
            } else { NA }
          }
          
          cat(" Trend:", component_stats("trend"), "\n")
          if("yearly" %in% names(forecast_df)) cat(" Yearly:", component_stats("yearly"), "\n")
          if("weekly" %in% names(forecast_df)) cat(" Weekly:", component_stats("weekly"), "\n")
          if("daily" %in% names(forecast_df)) cat(" Daily:", component_stats("daily"), "\n")
          if("holidays" %in% names(forecast_df)) cat(" Holidays:", component_stats("holidays"), "\n")
        }
      }
      
      # ===== ADD THIS RIGHT HERE =====
      # Show parameter optimization information if available
      if (!is.null(prophet_model$lucent_optimization)) {
        cat("\n--- Parameter Optimization ---\n")
        cat("Auto-optimized: YES\n")
        cat("Changepoint Prior Scale Used:", prophet_model$lucent_optimization$changepoint_prior_used, "\n")
        cat("Seasonality Prior Scale Used:", prophet_model$lucent_optimization$seasonality_prior_used, "\n")
        cat("Optimization Timestamp:", format(prophet_model$lucent_optimization$optimization_timestamp, "%Y-%m-%d %H:%M:%S"), "\n")
      } else if (model_info$method == "Prophet") {
        cat("\n--- Parameter Optimization ---\n")
        cat("Auto-optimized: NO (Manual parameters used)\n")
      }
      # ===== END OF ADDITION =====
      
      
      
      
      
    }, error = function(e) {
      cat("Error displaying model parameters:", e$message, "\n")
    })
  })
  
  # ===== Parameter Stability Plot =====
  output$parameter_stability <- renderPlotly({
    req(rv$model_objects, input$diagnostics_entity)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    if(is.null(model_info)) return(plot_ly() %>% layout(title = "Model not available"))
    
    model <- model_info$model
    method <- model_info$method
    
    tryCatch({
      if (method == "ARIMA") {
        entity_data <- rv$processed_data %>% filter(Entity_Name == input$diagnostics_entity) %>% arrange(Date)
        if(nrow(entity_data) < 30) return(plot_ly() %>% layout(title="Need more data for stability plot"))
        
        freq_details <- get_current_frequency()
        ts_data <- ts(entity_data$Volume, frequency = freq_details$freq_numeric)
        arima_order_obj <- arimaorder(model)
        
        num_windows <- 10
        min_window_size <- max(30, floor(length(ts_data) * 0.5))
        if(length(ts_data) <= min_window_size) {
          return(plot_ly() %>% layout(title="Need more data for stability plot"))
        }
        
        window_ends <- floor(seq(min_window_size, length(ts_data), length.out = num_windows))
        param_results <- list()
        
        for (i in 1:length(window_ends)) {
          window_data <- window(ts_data, end = time(ts_data)[window_ends[i]])
          req_len <- sum(arima_order_obj[c(1,3,4,6)]) + arima_order_obj[5] * arima_order_obj[7] + 5
          
          if(length(window_data) < req_len) next
          
          tryCatch({
            window_model <- Arima(window_data, 
                                  order=arima_order_obj[1:3], 
                                  seasonal=list(
                                    order=arima_order_obj[4:6], 
                                    period=arima_order_obj[7]
                                  ))
            
            if (!is.null(window_model$coef) && length(window_model$coef) > 0) {
              param_results[[length(param_results) + 1]] <- list(
                window_size = window_ends[i], 
                params = as.list(window_model$coef)
              )
            }
          }, error = function(e) {warning(paste("Stability fit failed for ARIMA window", i))})
        }
        
        if(length(param_results) < 2) {
          return(plot_ly() %>% layout(title="Could not fit models on enough windows"))
        }
        
        param_names <- unique(unlist(lapply(param_results, function(x) names(x$params))))
        if(is.null(param_names)) {
          return(plot_ly() %>% layout(title="No parameters found in windowed models"))
        }
        
        param_stability_df <- data.frame(window_size = sapply(param_results, `[[`, "window_size"))
        for(p_name in param_names) {
          param_stability_df[[p_name]] <- sapply(param_results, function(x) x$params[[p_name]][1])
        }
        
        param_stability_df_long <- param_stability_df %>% 
          tidyr::pivot_longer(-window_size, names_to="Parameter", values_to="Value")
        
        plot_ly(param_stability_df_long, 
                x=~window_size, y=~Value, color=~Parameter, 
                type='scatter', mode='lines+markers') %>%
          layout(title="ARIMA Parameter Stability", 
                 xaxis=list(title="Window End Size"), 
                 yaxis=list(title="Parameter Value"))
        
      } else if (method == "Exponential Smoothing") {
        entity_data <- rv$processed_data %>% filter(Entity_Name == input$diagnostics_entity) %>% arrange(Date)
        if(nrow(entity_data) < 30) return(plot_ly() %>% layout(title="Need more data for stability plot"))
        
        freq_details <- get_current_frequency()
        ts_data <- ts(entity_data$Volume, frequency = freq_details$freq_numeric)
        ets_model_string <- model$method
        
        num_windows <- 10
        req_len_ets <- if(grepl("S", model$components[3])) 2 * freq_details$freq_numeric + 5 else 10
        min_window_size <- max(req_len_ets, floor(length(ts_data) * 0.5))
        
        if(length(ts_data) <= min_window_size) {
          return(plot_ly() %>% layout(title="Need more data for ETS stability plot"))
        }
        
        window_ends <- floor(seq(min_window_size, length(ts_data), length.out = num_windows))
        param_results <- list()
        
        for (i in 1:length(window_ends)) {
          window_data <- window(ts_data, end = time(ts_data)[window_ends[i]])
          tryCatch({
            window_model <- ets(window_data, model=ets_model_string)
            if (!is.null(window_model$par) && length(window_model$par) > 0) {
              param_results[[length(param_results)+1]] <- list(
                window_size = window_ends[i], 
                params = as.list(window_model$par)
              )
            }
          }, error = function(e) {warning(paste("Stability fit failed for ETS window", i))})
        }
        
        if(length(param_results) < 2) {
          return(plot_ly() %>% layout(title="Could not fit models on enough windows"))
        }
        
        param_names <- unique(unlist(lapply(param_results, function(x) names(x$params))))
        if(is.null(param_names)) {
          return(plot_ly() %>% layout(title="No parameters found in windowed models"))
        }
        
        param_stability_df <- data.frame(window_size = sapply(param_results, `[[`, "window_size"))
        for(p_name in param_names) {
          param_stability_df[[p_name]] <- sapply(param_results, function(x) x$params[[p_name]][1])
        }
        
        param_stability_df_long <- param_stability_df %>% 
          tidyr::pivot_longer(-window_size, names_to="Parameter", values_to="Value")
        
        plot_ly(param_stability_df_long, 
                x=~window_size, y=~Value, color=~Parameter, 
                type='scatter', mode='lines+markers') %>%
          layout(title="ETS Parameter Stability", 
                 xaxis=list(title="Window End Size"), 
                 yaxis=list(title="Parameter Value"))
        
      } else if (method == "Prophet") {
        prophet_model <- model
        if(is.null(prophet_model$changepoints) || length(prophet_model$changepoints) == 0) {
          return(plot_ly() %>% layout(title="No Trend Changepoints in Prophet Model"))
        }
        
        if(is.null(prophet_model$params$delta) || 
           ncol(prophet_model$params$delta) != length(prophet_model$changepoints)) {
          return(plot_ly() %>% layout(title="Changepoint effects (delta) not found or mismatch length"))
        }
        
        cp_df <- data.frame(
          date = tryCatch(as.Date(prophet_model$changepoints), error=function(e) NA),
          effect = as.numeric(prophet_model$params$delta[1, ])
        ) %>% filter(!is.na(date)) %>% arrange(date)
        
        if(nrow(cp_df) == 0) {
          return(plot_ly() %>% layout(title="No valid changepoints found"))
        }
        
        plot_ly(cp_df, x=~date, y=~effect, type='bar', name='Changepoint Magnitude') %>%
          layout(title="Prophet Trend Changepoint Magnitudes", 
                 xaxis=list(title="Date"), 
                 yaxis=list(title="Change in Trend Rate"))
      } else {
        plot_ly() %>% layout(title="Stability plot not available for this method")
      }
    }, error = function(e){
      plot_ly() %>% layout(title = paste("Error creating stability plot:", e$message))
    })
  })
  
  # ===== Seasonality Plot =====
  output$seasonality_plot <- renderPlotly({
    req(rv$forecast_generated, input$diagnostics_entity, rv$model_objects)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    if(is.null(model_info)) return(plot_ly() %>% layout(title = "Model not available"))
    
    tryCatch({
      if(model_info$method == "Prophet") {
        if (!is.null(model_info$model) && !is.null(model_info$forecast_output$prophet_fcst_df)) {
          # Prophet seasonality plots would ideally use prophet_plot_components
          # Manual implementation for plotly:
          forecast_df <- model_info$forecast_output
          
          # ===== Seasonality Plot (continued) =====
          prophet_model <- model_info$model
          forecast_df <- model_info$forecast_output$prophet_fcst_df
          
          # Extract yearly seasonality if available
          if("yearly" %in% names(forecast_df)) {
            # Group by day of year to create yearly pattern
            yearly_df <- forecast_df %>%
              mutate(doy = lubridate::yday(ds)) %>%
              group_by(doy) %>%
              summarise(yearly_effect = mean(yearly, na.rm = TRUE)) %>%
              arrange(doy)
            
            # Create dates for a full year for better x-axis
            year_dates <- seq.Date(from = as.Date("2023-01-01"), 
                                   by = "day", length.out = 366) %>%
              head(365)
            
            yearly_df$date <- year_dates[yearly_df$doy]
            
            yearly_plot <- plot_ly(yearly_df, x = ~date, y = ~yearly_effect, 
                                   type = 'scatter', mode = 'lines',
                                   line = list(color = '#3c8dbc', width = 2),
                                   name = 'Yearly') %>%
              layout(title = "Yearly Seasonality Pattern",
                     xaxis = list(title = "Month", 
                                  tickformat = "%b",
                                  tickmode = "array",
                                  tickvals = seq.Date(from = as.Date("2023-01-01"), 
                                                      to = as.Date("2023-12-01"), 
                                                      by = "month")),
                     yaxis = list(title = "Effect"),
                     showlegend = FALSE)
          } else {
            yearly_plot <- plot_ly() %>% 
              layout(title = "No Yearly Seasonality Component")
          }
          
          # Extract weekly seasonality if available
          if("weekly" %in% names(forecast_df)) {
            # Group by day of week
            weekly_df <- forecast_df %>%
              mutate(dow = lubridate::wday(ds, label = TRUE)) %>%
              group_by(dow) %>%
              summarise(weekly_effect = mean(weekly, na.rm = TRUE))
            
            weekly_plot <- plot_ly(weekly_df, x = ~dow, y = ~weekly_effect, 
                                   type = 'bar',
                                   marker = list(color = '#00a65a'),
                                   name = 'Weekly') %>%
              layout(title = "Weekly Seasonality Pattern",
                     xaxis = list(title = "Day of Week"),
                     yaxis = list(title = "Effect"),
                     showlegend = FALSE)
          } else {
            weekly_plot <- plot_ly() %>% 
              layout(title = "No Weekly Seasonality Component")
          }
          
          # Combine plots
          subplot(yearly_plot, weekly_plot, nrows = 2, shareX = FALSE) %>%
            layout(title = paste("Prophet Seasonality for", input$diagnostics_entity),
                   height = 600)
        } else {
          plot_ly() %>% layout(title = "Prophet forecast data needed for seasonality plot")
        }
      } else {
        # For ARIMA/ETS use seasonal subseries plot
        entity_data <- rv$processed_data %>% filter(Entity_Name == input$diagnostics_entity)
        freq_details <- get_current_frequency()
        ts_freq <- freq_details$freq_numeric
        
        if(ts_freq <= 1) {
          return(plot_ly() %>% layout(title="Seasonality plot requires frequency > 1"))
        }
        
        ts_data <- ts(entity_data$Volume, frequency = ts_freq)
        if(length(na.omit(ts_data)) < 2 * ts_freq) {
          return(plot_ly() %>% layout(title="Need at least 2 periods of non-NA data for seasonality plot"))
        }
        
        # Manual seasonal subseries plot for plotly
        # Extract seasons/cycles and gather data
        cycle_data <- data.frame(
          value = as.numeric(ts_data),
          season = as.factor(cycle(ts_data))
        ) %>% filter(!is.na(value))
        
        # Calculate means by season
        season_means <- cycle_data %>%
          group_by(season) %>%
          summarise(mean_value = mean(value, na.rm = TRUE))
        
        # Create labels for seasons based on frequency
        season_labels <- if(ts_freq == 12) {
          month.abb # January, February, etc.
        } else if(ts_freq == 4) {
          c("Q1", "Q2", "Q3", "Q4") # Quarters
        } else if(ts_freq == 52 || ts_freq == 53) {
          paste0("W", 1:ts_freq) # Week numbers
        } else if(ts_freq == 7) {
          c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun") # Days
        } else {
          as.character(1:ts_freq) # Generic numbering
        }
        
        # Adjust labels if there are fewer seasons than frequency
        if(length(unique(cycle_data$season)) <= length(season_labels)) {
          season_labels <- season_labels[1:length(unique(cycle_data$season))]
        }
        
        # Create seasonal subseries plot
        plot_ly() %>%
          add_trace(data = cycle_data, x = ~season, y = ~value, 
                    type = 'scatter', mode = 'markers',
                    marker = list(color = '#3c8dbc', size = 8, opacity = 0.7), 
                    name = 'Values') %>%
          add_trace(data = season_means, x = ~season, y = ~mean_value, 
                    type = 'scatter', mode = 'lines+markers',
                    line = list(color = '#00a65a', width = 2),
                    marker = list(color = '#00a65a', size = 10),
                    name = 'Season Mean') %>%
          layout(title = paste("Seasonal Pattern for", input$diagnostics_entity),
                 xaxis = list(title = "Season", 
                              tickvals = 1:length(season_labels),
                              ticktext = season_labels),
                 yaxis = list(title = "Volume"))
      }
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error creating seasonality plot:", e$message))
    })
  })
  
  # ===== Seasonal Patterns =====
  output$seasonal_patterns <- renderPrint({
    req(rv$processed_data, input$diagnostics_entity)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    
    entity_data <- rv$processed_data %>% filter(Entity_Name == input$diagnostics_entity) %>% arrange(Date)
    freq_details <- get_current_frequency()
    ts_freq <- freq_details$freq_numeric
    
    cat("===== Seasonal Pattern Summary =====\n")
    cat("Item:", input$diagnostics_entity, "\n")
    cat("Assumed Frequency:", freq_details$freq_unit, "(Numeric:", ts_freq, ")\n\n")
    
    if (ts_freq <= 1) {
      cat("Frequency is 1 (or less), no seasonal analysis performed.\n")
      return()
    }
    
    ts_data <- ts(entity_data$Volume, frequency = ts_freq)
    if(length(na.omit(ts_data)) < 2 * ts_freq) {
      cat("Need at least 2 periods of non-NA data for seasonal analysis.\n")
      return()
    }
    
    # Analyze seasonality based on method if available, otherwise just data
    tryCatch({
      if (!is.null(model_info) && model_info$method == "Prophet") {
        # Report Prophet components
        if (!is.null(model_info$model) && !is.null(model_info$forecast_output$prophet_fcst_df)) {
          forecast_df <- model_info$forecast_output$prophet_fcst_df
          cat("Prophet Seasonality Components (Range):\n")
          has_seasonality <- FALSE
          if("yearly" %in% names(forecast_df)) { 
            cat("- Yearly:", round(diff(range(forecast_df$yearly, na.rm=TRUE)),2), "\n")
            has_seasonality=TRUE
          }
          if("weekly" %in% names(forecast_df)) { 
            cat("- Weekly:", round(diff(range(forecast_df$weekly, na.rm=TRUE)),2), "\n")
            has_seasonality=TRUE
          }
          if("daily" %in% names(forecast_df)) { 
            cat("- Daily:", round(diff(range(forecast_df$daily, na.rm=TRUE)),2), "\n")
            has_seasonality=TRUE
          }
          if(!has_seasonality) cat("- None detected or specified\n")
        } else { 
          cat("Prophet model/forecast data not available.\n") 
        }
        
      } else {
        # Use STL decomposition for ARIMA/ETS or if no model info
        decomp <- stl(ts_data, s.window = "periodic", na.action = na.omit)
        seasonal_comp <- decomp$time.series[, "seasonal"]
        cat("STL Decomposition Seasonal Component:\n")
        cat("- Range:", round(diff(range(seasonal_comp, na.rm = TRUE)), 2), "\n")
        cat("- Standard Deviation:", round(sd(seasonal_comp, na.rm = TRUE), 4), "\n\n")
        
        # Analyze by period
        seasonal_df <- data.frame(
          seasonal = as.numeric(seasonal_comp),
          period = cycle(seasonal_comp)
        )
        period_means <- aggregate(seasonal ~ period, seasonal_df, mean)
        period_means <- period_means[order(period_means$seasonal, decreasing = TRUE), ]
        
        cat("Average Seasonal Effect by Period:\n")
        print(format(period_means, digits=4), row.names = FALSE)
      }
    }, error = function(e) {
      cat("Error during seasonal pattern analysis:", e$message, "\n")
    })
  })
  
  # ===== Seasonal Strength =====
  output$seasonal_strength <- renderPrint({
    req(rv$processed_data, input$diagnostics_entity)
    entity_data <- rv$processed_data %>% filter(Entity_Name == input$diagnostics_entity) %>% arrange(Date)
    freq_details <- get_current_frequency()
    ts_freq <- freq_details$freq_numeric
    
    cat("===== Seasonality Strength =====\n")
    cat("Item:", input$diagnostics_entity, "\n\n")
    
    if (ts_freq <= 1) {
      cat("Frequency is 1 (or less), seasonality strength not calculated.\n")
      return()
    }
    
    ts_data <- ts(entity_data$Volume, frequency = ts_freq)
    if(length(na.omit(ts_data)) < 2 * ts_freq + 1) {
      cat("Need more than 2 periods of non-NA data for strength calculation.\n")
      return()
    }
    
    tryCatch({
      # Use forecast package decomposition for strength measures
      decomp_stl <- stl(ts_data, s.window="periodic", na.action = na.omit)
      trend_strength_val <- tryCatch(var(trendcycle(decomp_stl), na.rm=TRUE), error=function(e) NA)
      seasonal_strength_val <- tryCatch(var(seasonal(decomp_stl), na.rm=TRUE), error=function(e) NA)
      remainder_strength_val <- tryCatch(var(remainder(decomp_stl), na.rm=TRUE), error=function(e) NA)
      
      if(is.na(remainder_strength_val) || remainder_strength_val < 1e-9){
        cat("Could not calculate strength: Remainder variance is zero or NA.\n")
        return()
      }
      
      # Strength calculations
      seasonal_strength <- NA
      if (!is.na(seasonal_strength_val) && !is.na(remainder_strength_val)) {
        var_season_rem <- var(seasonal(decomp_stl) + remainder(decomp_stl), na.rm = TRUE)
        if(!is.na(var_season_rem) && var_season_rem > 1e-9) {
          seasonal_strength <- max(0, 1 - remainder_strength_val / var_season_rem)
        }
      }
      
      trend_strength <- NA
      if (!is.na(trend_strength_val) && !is.na(remainder_strength_val)) {
        var_trend_rem <- var(trendcycle(decomp_stl) + remainder(decomp_stl), na.rm = TRUE)
        if(!is.na(var_trend_rem) && var_trend_rem > 1e-9) {
          trend_strength <- max(0, 1 - remainder_strength_val / var_trend_rem)
        }
      }
      
      cat("Strength based on STL Decomposition:\n")
      cat("- Seasonal Strength:", if(is.na(seasonal_strength)) "NA" else round(seasonal_strength, 4), "\n")
      cat("- Trend Strength:", if(is.na(trend_strength)) "NA" else round(trend_strength, 4), "\n\n")
      
      # Interpretation helper
      interpret_strength <- function(val) {
        if(is.na(val)) return("N/A")
        if(val > 0.6) return("Strong")
        if(val > 0.4) return("Moderate")
        return("Weak")
      }
      cat("Interpretation:\n")
      cat("- Seasonality:", interpret_strength(seasonal_strength), "\n")
      cat("- Trend:", interpret_strength(trend_strength), "\n")
      
    }, error=function(e){
      cat("Error during seasonality strength calculation:", e$message, "\n")
    })
  })
  
  # ===== Forecast Error Plot =====
  output$forecast_error_plot <- renderPlotly({
    # This relies on cross-validation results if available
    if(!is.null(rv$comparison_metrics)) {
      # Plot comparison metrics (e.g., MAPE)
      df <- rv$comparison_metrics %>% filter(!is.na(MAPE))
      if(nrow(df) > 0) {
        plot_ly(df, x=~Model, y=~MAPE, type='bar', name='MAPE (CV)') %>%
          layout(title="Cross-Validation Error (MAPE)", yaxis=list(title="MAPE (%)"))
      } else {
        plot_ly() %>% layout(title="No Comparison CV Metrics Available")
      }
    } else {
      # Fallback to in-sample residual distribution
      residuals_val <- get_residuals()
      if (is.null(residuals_val)) {
        plot_ly() %>% layout(title = "In-Sample Residuals Not Available")
      } else {
        plot_ly(x = ~residuals_val, type = 'histogram', nbinsx = 30, name="Residuals") %>%
          layout(title = "Distribution of In-Sample Residuals", 
                 xaxis = list(title = "Residual"), 
                 yaxis = list(title = "Frequency"))
      }
    }
  })
  
  # ===== Error Distribution =====
  output$error_distribution <- renderPlotly({
    residuals_val <- get_residuals()
    if (is.null(residuals_val)) {
      return(plot_ly() %>% layout(title = "Residuals Not Available"))
    }
    
    mean_res <- mean(residuals_val)
    plot_ly(x = ~residuals_val, type = 'histogram', 
            nbinsx = 30, marker = list(color = '#3c8dbc'), 
            name = 'Residuals') %>%
      layout(title = "Distribution of In-Sample Residuals",
             xaxis = list(title = "Residual"), 
             yaxis = list(title = "Frequency"),
             showlegend = FALSE,
             shapes = list(
               list(type = 'line', x0 = mean_res, x1 = mean_res, 
                    y0 = 0, y1 = 1, yref = 'paper', 
                    line = list(color = '#f39c12', width = 2, dash = 'dash'), 
                    name="Mean"),
               list(type = 'line', x0 = 0, x1 = 0, 
                    y0 = 0, y1 = 1, yref = 'paper', 
                    line = list(color = '#00a65a', width = 1), 
                    name="Zero")
             ),
             annotations = list(
               list(x = mean_res, y = 0.95, yref = 'paper', 
                    text = paste("Mean:", round(mean_res, 2)), 
                    showarrow = FALSE, xanchor='center')
             )
      )
  })
  
  # ===== Error Statistics =====
  output$error_stats <- renderPrint({
    residuals_val <- get_residuals()
    metrics <- rv$performance_metrics[[input$diagnostics_entity]]
    
    if (is.null(residuals_val)) {
      cat("Residuals not available.")
      return()
    }
    
    cat("===== In-Sample Error/Residual Statistics =====\n")
    cat("Number:", length(residuals_val), "\n\n")
    print(summary(residuals_val))
    cat("Std Dev:", round(sd(residuals_val), 4), "\n\n")
    
    cat("In-Sample Performance Metrics:\n")
    if(!is.null(metrics)){
      cat("- MAE:", metrics$MAE, "\n")
      cat("- RMSE:", metrics$RMSE, "\n")
      cat("- MAPE:", metrics$MAPE, "%\n\n")
    } else {
      cat("- No performance metrics available\n\n")
    }
    
    # Test for Bias (mean significantly different from zero?)
    if(length(residuals_val) > 1 && length(unique(round(residuals_val,6))) > 1) {
      t_test <- t.test(residuals_val)
      cat("Test for Bias (t-test on mean):\n")
      cat(" t =", round(t_test$statistic, 4), 
          ", p-value =", format.pval(t_test$p.value, digits = 4), "\n")
      cat(" Interpretation:", 
          ifelse(t_test$p.value > 0.05, 
                 "Mean not significantly different from zero (good)", 
                 "Mean significantly different from zero (bias likely)"), "\n")
    } else {
      cat("T-test for bias not applicable (n<=1 or constant residuals).\n")
    }
  })
  
  # ===== Diagnostics Info =====
  output$diagnostics_info <- renderPrint({
    req(rv$processed_data, input$diagnostics_entity)
    entity_data <- rv$processed_data %>% filter(Entity_Name == input$diagnostics_entity) %>% arrange(Date)
    model_info <- rv$model_objects[[input$diagnostics_entity]]
    metrics <- rv$performance_metrics[[input$diagnostics_entity]]
    
    cat("===== Diagnostics Summary =====\n")
    cat("Item:", input$diagnostics_entity, "\n\n")
    
    cat("--- Data Info ---\n")
    cat("Observations:", nrow(entity_data), "\n")
    cat("Date Range:", format(min(entity_data$Date), "%Y-%m-%d"), 
        "to", format(max(entity_data$Date), "%Y-%m-%d"), "\n")
    
    freq_det <- get_current_frequency()
    cat("Current Frequency Setting:", freq_det$freq_unit, 
        "(Numeric:", freq_det$freq_numeric, ")\n\n")
    
    cat("--- Model Info ---\n")
    if(!is.null(model_info)){
      cat("Method:", model_info$method, "\n")
      model_obj <- model_info$model
      
      if (model_info$method == "ARIMA") {
        cat(" ARIMA Order:", paste(arimaorder(model_obj), collapse = ","), "\n")
        cat(" AIC:", round(model_obj$aic, 2), "\n")
      } else if (model_info$method == "Exponential Smoothing") {
        cat(" ETS Model:", model_obj$method, "\n")
        cat(" AIC:", round(model_obj$aic, 2), "\n")
      } else if (model_info$method == "Prophet") {
        cat(" Growth Type:", model_obj$growth, "\n")
        active_s <- names(model_obj$seasonalities)
        cat(" Active Seasonalities:", 
            if(length(active_s)>0) paste(active_s, collapse=", ") else "None", "\n")
        
        if (!is.null(model_obj$holidays)) {
          cat(" Holidays:", model_obj$country_holidays, "\n")
        }
      }
    } else {
      cat("No model details available (forecast may have failed or not run).\n")
    }
    
    cat("\n--- In-Sample Performance ---\n")
    if(!is.null(metrics) && !is.na(metrics$MAE)){
      cat(" MAE:", metrics$MAE, "\n")
      cat(" RMSE:", metrics$RMSE, "\n")
      cat(" MAPE:", metrics$MAPE, "%\n")
    } else {
      cat("No performance metrics available.\n")
    }
  })
  
  # ===== Model Comparison =====
  observeEvent(input$run_comparison, {
    req(rv$processed_data, input$diagnostics_entity)
    entity_data <- rv$processed_data %>% filter(Entity_Name == input$diagnostics_entity) %>% arrange(Date)
    
    if(nrow(entity_data) < 30) {
      showNotification("Not enough data (need ~30+ points) for reliable model comparison using Cross-Validation.", 
                       type="error")
      return()
    }
    
    models_to_compare <- c(
      if(input$compare_arima) "ARIMA", 
      if(input$compare_ets) "ETS", 
      if(input$compare_prophet) "Prophet"
    )
    
    if(length(models_to_compare) == 0) {
      showNotification("Select at least one model to compare.", type="warning")
      return()
    }
    
    withProgress(message = 'Comparing models via Cross-Validation...', value = 0, {
      tryCatch({
        # --- CV Setup ---
        freq_details <- get_current_frequency()
        ts_freq <- freq_details$freq_numeric
        prophet_freq <- freq_details$freq_unit
        
        h_cv <- min(12, floor(nrow(entity_data) * 0.15))
        initial_train <- floor(nrow(entity_data) * 0.7)
        
        if(h_cv < 1 || initial_train < 15) {
          stop("Not enough data for reliable cross-validation setup.")
        }
        
        ts_data <- ts(entity_data$Volume, frequency = ts_freq)
        n_obs <- length(ts_data)
        
        # Define forecast origins for rolling window CV
        # Step forward by h_cv/2 or at least 1
        forecast_origins <- seq(initial_train, n_obs - h_cv, by = max(1, floor(h_cv/2)))
        
        if(length(forecast_origins) < 3) {
          stop("CV setup results in too few (< 3) forecast windows.")
        }
        
        comparison_results_list <- list()
        cv_errors_all_models <- list()
        
        # --- Loop Through Models ---
        for (model_name in models_to_compare) {
          incProgress(1/length(models_to_compare), 
                      detail = paste("Running CV for", model_name))
          
          errors_model_folds <- list()
          
          # --- Loop Through CV Folds ---
          for(k_idx in 1:length(forecast_origins)) {
            k <- forecast_origins[k_idx]
            train_subset_ts <- window(ts_data, end = time(ts_data)[k])
            test_subset_actual_ts <- window(ts_data, 
                                            start = time(ts_data)[k + 1], 
                                            end = time(ts_data)[k + h_cv])
            test_subset_actual <- as.numeric(test_subset_actual_ts)
            
            # Skip fold if train subset is too short
            min_len_fold <- if(model_name=="Prophet") 15 else if(ts_freq>1) 2*ts_freq+5 else 10
            if(length(train_subset_ts) < min_len_fold) next
            
            pred <- NULL # Initialize prediction for this fold
            
            tryCatch({
              if(model_name == "ARIMA") {
                # Use simpler auto.arima settings for speed in CV
                fit <- auto.arima(train_subset_ts, stepwise=TRUE, approximation=TRUE)
                pred <- forecast(fit, h = h_cv)$mean
                
              } else if(model_name == "ETS") {
                fit <- ets(train_subset_ts, allow.multiplicative.trend=FALSE)
                pred <- forecast(fit, h = h_cv)$mean
                
              } else if(model_name == "Prophet") {
                train_df_prophet <- data.frame(
                  ds=as.Date(time(train_subset_ts)), 
                  y=as.numeric(train_subset_ts)
                ) %>% filter(!is.na(y))
                
                if(nrow(train_df_prophet) < 15) next
                
                n_obs_cv <- nrow(train_df_prophet)
                potential_cps_cv <- max(0, floor(n_obs_cv * 0.8) - 1)
                n_changepoints_adjusted_cv <- min(15, potential_cps_cv)
                
                # Use faster settings for CV Prophet
                fit <- prophet(train_df_prophet,
                               n.changepoints = n_changepoints_adjusted_cv,
                               yearly.seasonality='auto', 
                               weekly.seasonality='auto', 
                               daily.seasonality='auto',
                               interval.width = 0.8, 
                               uncertainty.samples = 50)
                
                future <- make_future_dataframe(fit, periods=h_cv, freq=prophet_freq)
                fcst <- predict(fit, future)
                pred <- tail(fcst$yhat, h_cv)
              }
              
              # Store errors if prediction successful and lengths match
              if(!is.null(pred) && length(pred) == length(test_subset_actual)) {
                errors_model_folds[[k_idx]] <- test_subset_actual - as.numeric(pred)
              } else {
                errors_model_folds[[k_idx]] <- rep(NA, h_cv)
              }
              
            }, error = function(e){
              warning(paste("CV Error for", model_name, "at k=", k, ":", e$message))
              errors_model_folds[[k_idx]] <- rep(NA, h_cv)
            })
          } # End CV loop for one model
          
          # --- Aggregate Results for Model ---
          errors_model_combined <- na.omit(unlist(errors_model_folds))
          cv_errors_all_models[[model_name]] <- errors_model_combined
          
          if(length(errors_model_combined) > 0) {
            mae <- mean(abs(errors_model_combined))
            rmse <- sqrt(mean(errors_model_combined^2))
            
            # Calculate MAPE based on actual values used in CV
            actuals_cv <- na.omit(unlist(sapply(1:length(forecast_origins), function(k_idx) {
              k <- forecast_origins[k_idx]
              as.numeric(window(ts_data, start=time(ts_data)[k+1], end=time(ts_data)[k+h_cv]))
            })))
            
            # Align actuals with the non-NA errors
            actuals_for_mape <- actuals_cv[1:length(errors_model_combined)]
            valid_idx_mape <- actuals_for_mape != 0 & 
              is.finite(actuals_for_mape) & 
              is.finite(errors_model_combined)
            
            mape <- if(sum(valid_idx_mape)>0) {
              mean(abs(errors_model_combined[valid_idx_mape] / 
                         actuals_for_mape[valid_idx_mape])) * 100 
            } else {
              NA
            }
            
            comparison_results_list[[model_name]] <- data.frame(
              Model=model_name, 
              MAE=round(mae,4), 
              RMSE=round(rmse,4), 
              MAPE=round(mape,4)
            )
          } else {
            comparison_results_list[[model_name]] <- data.frame(
              Model=model_name, 
              MAE=NA, 
              RMSE=NA, 
              MAPE=NA
            )
            warning(paste("No valid forecast errors generated for", model_name, "during CV."))
          }
        } # End loop through models
        
        # --- Finalize & Update UI ---
        if(length(comparison_results_list) > 0) {
          rv$comparison_metrics <- bind_rows(comparison_results_list)
        } else {
          rv$comparison_metrics <- NULL
          stop("Cross-validation failed for all selected models.")
        }
        
        # --- Update Comparison Table ---
        output$comparison_table <- renderDT({
          req(rv$comparison_metrics)
          df_display <- rv$comparison_metrics
          datatable(df_display, 
                    options=list(dom='t', pageLength = -1), 
                    rownames=FALSE, 
                    caption = "Cross-Validation Performance Metrics") %>%
            formatStyle('MAE', 
                        backgroundColor = styleEqual(min(df_display$MAE, na.rm=TRUE), '#d5f5e3')) %>%
            formatStyle('RMSE', 
                        backgroundColor = styleEqual(min(df_display$RMSE, na.rm=TRUE), '#d5f5e3')) %>%
            formatStyle('MAPE', 
                        backgroundColor = styleEqual(min(df_display$MAPE, na.rm=TRUE), '#d5f5e3')) %>%
            formatRound(c('MAE', 'RMSE', 'MAPE'), digits=4)
        })
        
        # --- Update Comparison Plot ---
        output$comparison_plot <- renderPlotly({
          req(cv_errors_all_models)
          if(length(cv_errors_all_models) == 0) {
            return(plot_ly() %>% layout(title="No CV errors to plot"))
          }
          
          # Create dataframe for boxplot
          error_df_list <- lapply(names(cv_errors_all_models), function(m_name){
            data.frame(Model=m_name, Error=cv_errors_all_models[[m_name]])
          })
          error_df_combined <- bind_rows(error_df_list)
          
          plot_ly(error_df_combined, y = ~Error, color = ~Model, type = "box") %>%
            layout(title="Distribution of Cross-Validation Forecast Errors", 
                   yaxis=list(title="Error", zeroline=TRUE))
        })
        
        # --- Update Diagnostic Summary Badges ---
        if(!is.null(rv$comparison_metrics) && nrow(rv$comparison_metrics) > 0){
          best_model_row <- rv$comparison_metrics %>% 
            filter(MAPE == min(MAPE, na.rm=TRUE)) %>% 
            slice(1)
          
          best_model_name <- if(nrow(best_model_row)>0) best_model_row$Model else "N/A"
          min_mape <- if(nrow(best_model_row)>0) best_model_row$MAPE else Inf
          
          # Update badges based on best model performance (heuristic)
          acc_level <- if(is.na(min_mape)) "grey" else if(min_mape < 10) "success" else if(min_mape < 25) "warning" else "danger"
          acc_text <- if(is.na(min_mape)) "N/A" else if(min_mape < 10) "Good" else if(min_mape < 25) "Moderate" else "Poor"
          acc_width <- if(is.na(min_mape)) 50 else max(10, min(95, 100 - min_mape * 2)) # Scale width
          
          shinyjs::html("forecast_accuracy_badge", acc_text)
          shinyjs::runjs(paste0("$('#forecast_accuracy_badge').removeClass('badge-success badge-warning badge-danger badge-info badge-secondary').addClass('badge-", acc_level, "');"))
          shinyjs::runjs(paste0("$('#forecast_accuracy_bar').removeClass('bg-success bg-warning bg-danger bg-info bg-secondary').addClass('bg-", acc_level, "');"))
          shinyjs::runjs(paste0("document.getElementById('forecast_accuracy_bar').style.width = '", acc_width, "%';"))
          
          # Update other badges heuristically
          # These could be based on residual checks of the *final* model if needed
          
          # Set Residual Randomness badge based on Ljung-Box test
          residuals_val <- get_residuals()
          if(!is.null(residuals_val) && length(residuals_val) >= 10) {
            lb_lag <- min(10, length(residuals_val) %/% 5)
            lb_test <- tryCatch(Box.test(residuals_val, lag = lb_lag, type = "Ljung-Box"), 
                                error=function(e) NULL)
            
            if(!is.null(lb_test)) {
              lb_pval <- lb_test$p.value
              res_rand_level <- if(lb_pval > 0.05) "success" else if(lb_pval > 0.01) "warning" else "danger"
              res_rand_text <- if(lb_pval > 0.05) "Good" else if(lb_pval > 0.01) "Moderate" else "Poor"
              res_rand_width <- if(lb_pval > 0.05) 80 else if(lb_pval > 0.01) 50 else 20
              
              shinyjs::html("residual_randomness_badge", res_rand_text)
              shinyjs::runjs(paste0("$('#residual_randomness_badge').removeClass('badge-success badge-warning badge-danger badge-info badge-secondary').addClass('badge-", res_rand_level, "');"))
              shinyjs::runjs(paste0("$('#residual_randomness_bar').removeClass('bg-success bg-warning bg-danger bg-info bg-secondary').addClass('bg-", res_rand_level, "');"))
              shinyjs::runjs(paste0("document.getElementById('residual_randomness_bar').style.width = '", res_rand_width, "%';"))
            }
          }
          
          # Set Parameter Significance badge based on model type
          model_info <- rv$model_objects[[input$diagnostics_entity]]
          if(!is.null(model_info) && model_info$method == "ARIMA") {
            # Check if ARIMA coefficients are significant (p < 0.05)
            model_obj <- model_info$model
            param_sig_level <- "info" # Default
            param_sig_text <- "Check"
            param_sig_width <- 50
            
            if(!is.null(model_obj$coef) && !is.null(model_obj$var.coef)) {
              coef_significant <- FALSE
              
              tryCatch({
                var_diag <- diag(model_obj$var.coef)
                std_errors <- sqrt(pmax(1e-9, var_diag))
                t_vals <- model_obj$coef / std_errors
                df_resid <- length(model_obj$residuals) - length(model_obj$coef)
                p_vals <- 2 * pt(abs(t_vals), df = df_resid, lower.tail = FALSE)
                coef_significant <- sum(p_vals < 0.05) / length(p_vals) > 0.5
                
                param_sig_level <- if(coef_significant) "success" else "warning"
                param_sig_text <- if(coef_significant) "Good" else "Some Insignificant"
                param_sig_width <- if(coef_significant) 75 else 40
              }, error = function(e) {
                # Keep defaults if error occurs
              })
            }
            
            shinyjs::html("parameter_significance_badge", param_sig_text)
            shinyjs::runjs(paste0("$('#parameter_significance_badge').removeClass('badge-success badge-warning badge-danger badge-info badge-secondary').addClass('badge-", param_sig_level, "');"))
            shinyjs::runjs(paste0("$('#parameter_significance_bar').removeClass('bg-success bg-warning bg-danger bg-info bg-secondary').addClass('bg-", param_sig_level, "');"))
            shinyjs::runjs(paste0("document.getElementById('parameter_significance_bar').style.width = '", param_sig_width, "%';"))
          }
          
          # Set Overall Fit badge based on best model MAPE and residual randomness
          overall_level <- acc_level # Default to accuracy level
          overall_text <- acc_text   # Default to accuracy text
          overall_width <- acc_width # Default to accuracy width
          
          # Maybe improve to use multiple inputs
          shinyjs::html("overall_fit_badge", overall_text)
          shinyjs::runjs(paste0("$('#overall_fit_badge').removeClass('badge-success badge-warning badge-danger badge-info badge-secondary').addClass('badge-", overall_level, "');"))
          shinyjs::runjs(paste0("$('#overall_fit_bar').removeClass('bg-success bg-warning bg-danger bg-info bg-secondary').addClass('bg-", overall_level, "');"))
          shinyjs::runjs(paste0("document.getElementById('overall_fit_bar').style.width = '", overall_width, "%';"))
        }
        
      }, error = function(e) {
        showNotification(paste("Error during model comparison:", e$message), type="error")
        # Clear comparison outputs
        rv$comparison_metrics <- NULL
        output$comparison_table <- renderDT(NULL)
        output$comparison_plot <- renderPlotly(plot_ly() %>% layout(title="Comparison Failed"))
      })
    })
  })
  
  # ===== Download Diagnostics Report =====
  output$download_diagnostics <- downloadHandler(
    filename = function() {
      entity_name_clean <- gsub("[^A-Za-z0-9_]", "_", input$diagnostics_entity %||% "item")
      model_method <- rv$model_objects[[input$diagnostics_entity]]$method %||% "model"
      paste0("diagnostics_", entity_name_clean, "_", model_method, "_", Sys.Date(), ".", 
             input$export_diagnostics_format %||% "txt")
    },
    content = function(file) {
      req(rv$processed_data, input$diagnostics_entity)
      
      # Show busy indicator
      showModal(modalDialog(
        title = "Generating Report",
        "Please wait while we generate your diagnostics report...",
        footer = NULL,
        easyClose = FALSE
      ))
      
      tryCatch({
        # Gather info
        entity_name <- input$diagnostics_entity
        model_info <- rv$model_objects[[entity_name]]
        metrics <- rv$performance_metrics[[entity_name]]
        residuals_val <- get_residuals()
        
        # Create report content
        report_lines <- c(
          paste("===== Diagnostics Report for:", entity_name, "====="),
          paste("Generated:", Sys.time()),
          "\n--- Model ---",
          paste("Method:", model_info$method %||% "N/A")
        )
        
        if(!is.null(metrics)){
          report_lines <- c(report_lines,
                            "\n--- In-Sample Performance ---",
                            paste("MAE:", metrics$MAE %||% "NA"),
                            paste("RMSE:", metrics$RMSE %||% "NA"),
                            paste("MAPE:", metrics$MAPE %||% "NA", "%")
          )
        }
        
        if(!is.null(residuals_val)){
          report_lines <- c(report_lines,
                            "\n--- Residual Summary ---",
                            capture.output(summary(residuals_val))[-1],
                            paste("Std Dev:", round(sd(residuals_val), 4))
          )
          
          lb_lag <- min(10, length(residuals_val) %/% 5)
          if(lb_lag > 0) {
            lb_test <- Box.test(residuals_val, lag = lb_lag, type = "Ljung-Box")
            report_lines <- c(report_lines, 
                              "\nLjung-Box Test:", 
                              paste("  p-value:", format.pval(lb_test$p.value)))
          }
        }
        
        # Add comparison results if available
        if(!is.null(rv$comparison_metrics)){
          report_lines <- c(report_lines, "\n--- Model Comparison (CV) ---")
          report_lines <- c(report_lines, 
                            capture.output(print(rv$comparison_metrics, row.names=FALSE)))
        }
        
        # Write file based on format
        if (input$export_diagnostics_format == "pdf" || 
            input$export_diagnostics_format == "html" || 
            input$export_diagnostics_format == "docx") {
          
          # For simplicity in this implementation, just use text for all formats
          # In a real app, you'd create an R Markdown template and use rmarkdown::render
          writeLines(report_lines, file)
          
          showNotification(paste("Report exported as text. Full", 
                                 input$export_diagnostics_format, 
                                 "rendering requires R Markdown setup."), 
                           type="warning")
        } else {
          # Default to text
          writeLines(report_lines, file)
        }
        
        showNotification("Diagnostics report generated.", type="message")
        
      }, error = function(e) {
        showNotification(paste("Error generating report:", e$message), type="error")
      }, finally = {
        removeModal() # Remove the "please wait" modal
      })
    }
  )
  
  # Helper for showing missing values or other markers
  # (Ensure the `%||%` operator is defined or use base R alternatives)
  `%||%` <- function(a, b) if (is.null(a)) b else a        
  
  
  
  
  #Start of the Help Server Code 
  
  # ===== Help Tab Server Logic =====
  # The Help tab is primarily static content, but we can add some interactivity
  
  # Initialize the collapse states for FAQ panels
  observe({
    # When Help tab is selected, make sure the first FAQ item is open
    if (input$main_nav == "help" && input$help_tabs == "FAQ") {
      shinyjs::runjs("$('#faq1').collapse('show');")
    }
  })
  
  # Optional: Track help tab usage statistics
  observeEvent(input$help_tabs, {
    # Could log which help sections users view most often
    # This is just a placeholder for potential future analytics
    # console.log(paste("Help tab viewed:", input$help_tabs))
  })
  
  # Optional: Add a function to capture user feedback on help content
  # This would require adding a feedback form to the UI
  
  
  # ===== STEP 2: Create the Download Handler Server Function =====
  
  output$download_help_pdf <- downloadHandler(
    filename = function() {
      paste0("lucent_user_manual_", Sys.Date(), ".pdf")
    },
    content = function(file) {
      # Show loading modal
      showModal(modalDialog(
        title = "Generating PDF",
        "Please wait while we generate the user manual PDF...",
        footer = NULL,
        easyClose = FALSE
      ))
      
      # Temporary HTML file to store help content
      temp_html <- tempfile(fileext = ".html")
      
      # Create HTML content
      html_content <- tags$html(
        tags$head(
          tags$title("Lucent Time Series Forecasting - User Manual"),
          tags$style(HTML("
          body { 
            font-family: 'Helvetica', 'Arial', sans-serif; 
            line-height: 1.6; 
            color: #333; 
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
          }
          h1, h2, h3, h4 { 
            color: #337ab7; 
            margin-top: 30px;
            margin-bottom: 15px;
          }
          h1 { 
            color: #00a65a; 
            text-align: center;
            font-size: 28px;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
            margin-bottom: 30px;
          }
          .section { 
            margin-bottom: 40px; 
          }
          img { 
            max-width: 100%; 
            margin: 15px 0;
          }
          table { 
            border-collapse: collapse; 
            width: 100%; 
            margin: 15px 0;
          }
          th, td { 
            padding: 8px; 
            border: 1px solid #ddd; 
          }
          th { 
            background-color: #f5f5f5; 
          }
          .note { 
            background-color: #f8f9fa; 
            border-left: 4px solid #007bff; 
            padding: 10px 15px; 
            margin: 15px 0; 
          }
          .warning { 
            background-color: #fff3cd; 
            border-left: 4px solid #ffc107; 
            padding: 10px 15px; 
            margin: 15px 0; 
          }
          .footer { 
            text-align: center; 
            margin-top: 40px; 
            color: #777; 
            font-size: 12px; 
            border-top: 1px solid #eee;
            padding-top: 20px;
          }
        "))
        ),
        tags$body(
          # Cover Page
          tags$div(class = "section", style = "text-align: center; margin-top: 100px; margin-bottom: 100px;",
                   tags$h1("Lucent Time Series Forecasting", style = "font-size: 32px; margin-bottom: 10px;"),
                   tags$h2("User Manual", style = "color: #555; font-size: 24px;"),
                   tags$p(paste("Generated:", format(Sys.time(), "%B %d, %Y")), style = "margin-top: 50px;"),
                   tags$p("Forefront Consulting", style = "margin-top: 5px;")
          ),
          
          # Table of Contents
          tags$div(class = "section",
                   tags$h2("Table of Contents"),
                   tags$ul(
                     tags$li(tags$a("Application Overview", href = "#overview")),
                     tags$li(tags$a("Workflow", href = "#workflow")),
                     tags$li(
                       tags$a("Detailed Instructions", href = "#instructions"),
                       tags$ul(
                         tags$li(tags$a("Data Tab", href = "#data")),
                         tags$li(tags$a("Preprocessing Tab", href = "#preprocessing")),
                         tags$li(tags$a("Forecast Tab", href = "#forecast")),
                         tags$li(tags$a("Results Tab", href = "#results")),
                         tags$li(tags$a("Diagnostics Tab", href = "#diagnostics"))
                       )
                     ),
                     tags$li(tags$a("Frequently Asked Questions", href = "#faq")),
                     tags$li(tags$a("Best Practices", href = "#best-practices")),
                     tags$li(tags$a("Methods & Terminology", href = "#methods")),
                   )
          ),
          
          # Application Overview
          tags$div(id = "overview", class = "section",
                   tags$h2("Application Overview"),
                   tags$p("Lucent is a comprehensive time series forecasting application designed to help you analyze historical data and generate accurate predictions. This application combines powerful statistical methods with an intuitive interface to make forecasting accessible for all experience levels."),
                   tags$h4("Key Features:"),
                   tags$ul(
                     tags$li(HTML("<strong>Multiple Forecasting Methods:</strong> ARIMA, Exponential Smoothing, and Prophet models")),
                     tags$li(HTML("<strong>Data Preprocessing:</strong> Handle missing values, outliers, and transformations")),
                     tags$li(HTML("<strong>Interactive Visualizations:</strong> Explore your data with dynamic plots")),
                     tags$li(HTML("<strong>Model Diagnostics:</strong> Evaluate model performance and forecast accuracy")),
                     tags$li(HTML("<strong>Export Capabilities:</strong> Download results in various formats"))
                   )
          ),
          
          # Application Workflow
          tags$div(id = "workflow", class = "section",
                   tags$h2("Application Workflow"),
                   tags$p("Lucent follows a structured workflow for time series forecasting:"),
                   tags$ol(
                     tags$li(HTML("<strong>Data Upload</strong> - Import your time series data")),
                     tags$li(HTML("<strong>Preprocessing</strong> - Clean and transform data to improve forecast accuracy")),
                     tags$li(HTML("<strong>Forecast Configuration</strong> - Select model and parameters")),
                     tags$li(HTML("<strong>Results Analysis</strong> - Interpret forecasts and accuracy metrics")),
                     tags$li(HTML("<strong>Diagnostics</strong> - Evaluate model quality and compare approaches"))
                   )
          ),
          
          # Detailed Instructions
          tags$div(id = "instructions", class = "section",
                   tags$h2("Detailed Instructions"),
                   
                   # Data Tab
                   tags$div(id = "data", class = "sub-section",
                            tags$h3("Data Tab"),
                            tags$p("The Data tab is your starting point for any forecasting project. Here you'll upload your time series data and explore its characteristics."),
                            
                            tags$h4("Required Data Format"),
                            tags$p("Your dataset must contain these columns:"),
                            tags$ul(
                              tags$li(HTML("<strong>Date:</strong> Date column in yyyy-mm-dd format (or other standard date formats)")),
                              tags$li(HTML("<strong>Entity_ID:</strong> Unique identifier for each item/product")),
                              tags$li(HTML("<strong>Entity_Name:</strong> Descriptive name for each item")),
                              tags$li(HTML("<strong>Volume:</strong> Numeric values you want to forecast (e.g., sales, demand, counts)"))
                            ),
                            
                            tags$h4("Data Upload Steps"),
                            tags$ol(
                              tags$li("Click the 'Browse...' button in the Data Input section"),
                              tags$li("Select your CSV or Excel file from your computer"),
                              tags$li("Ensure 'File has header row' is checked if your file contains headers"),
                              tags$li("Once uploaded, your data will appear in the Data Preview section")
                            ),
                            
                            tags$div(class = "note", 
                                     tags$p(HTML("<strong>Tip:</strong> Not sure about the format? Download our template by clicking the 'Download Template' button."))
                            )
                   ),
                   
                   # Preprocessing Tab
                   tags$div(id = "preprocessing", class = "sub-section",
                            tags$h3("Preprocessing Tab"),
                            tags$p("Data preprocessing is critical for accurate forecasting. This tab helps you clean and transform your time series data before analysis."),
                            
                            tags$h4("Key Preprocessing Functions"),
                            
                            tags$h5("1. Handling Missing Values"),
                            tags$p("Missing values can distort your forecasts. Choose a method that fits your data:"),
                            tags$ul(
                              tags$li(HTML("<strong>Linear Interpolation:</strong> Fills gaps with values along a straight line between existing points")),
                              tags$li(HTML("<strong>Forward Fill:</strong> Propagates the last valid value forward")),
                              tags$li(HTML("<strong>Backward Fill:</strong> Uses the next valid value to fill gaps backward")),
                              tags$li(HTML("<strong>Mean/Median Fill:</strong> Replaces missing values with the average or median"))
                            ),
                            
                            tags$h5("2. Handling Outliers"),
                            tags$p("Outliers can significantly impact forecast accuracy:"),
                            tags$ul(
                              tags$li(HTML("<strong>Detection Methods:</strong> IQR, Z-Score, GESD")),
                              tags$li(HTML("<strong>Threshold:</strong> Controls sensitivity of detection")),
                              tags$li(HTML("<strong>Actions:</strong> Keep, Remove, Replace with Mean/Median, or Winsorize"))
                            ),
                            
                            tags$h5("3. Data Transformation"),
                            tags$p("Transform your data to improve forecast accuracy:"),
                            tags$ul(
                              tags$li(HTML("<strong>Log:</strong> Reduces skewness and stabilizes variance for data with multiplicative trends")),
                              tags$li(HTML("<strong>Square Root:</strong> Milder transformation than log")),
                              tags$li(HTML("<strong>Box-Cox:</strong> Automatically finds optimal transformation parameter"))
                            )
                   ),
                   
                   # Forecast Tab
                   tags$div(id = "forecast", class = "sub-section",
                            tags$h3("Forecast Tab"),
                            tags$p("The Forecast tab is where you select your forecasting method and configure parameters to generate predictions."),
                            
                            tags$h4("Forecasting Methods"),
                            tags$p("Lucent offers three powerful forecasting methods:"),
                            
                            tags$h5("ARIMA"),
                            tags$p(HTML("<strong>Best for:</strong> Data with clear trends and/or seasonality patterns")),
                            tags$p(HTML("<strong>Key settings:</strong>")),
                            tags$ul(
                              tags$li("Auto ARIMA (recommended for beginners)"),
                              tags$li("Manual parameter selection (p, d, q)"),
                              tags$li("Seasonal components (P, D, Q, S)")
                            ),
                            
                            tags$h5("Exponential Smoothing"),
                            tags$p(HTML("<strong>Best for:</strong> Data with trend and seasonal patterns, especially when recent observations are more important")),
                            tags$p(HTML("<strong>Key settings:</strong>")),
                            tags$ul(
                              tags$li("Auto ETS (recommended)"),
                              tags$li("Model type (ANN, AAN, AAA, etc.)"),
                              tags$li("Smoothing parameters (α, β, γ)")
                            ),
                            
                            tags$h5("Prophet"),
                            tags$p(HTML("<strong>Best for:</strong> Business time series with multiple seasonal patterns, holidays, and outliers")),
                            tags$p(HTML("<strong>Key settings:</strong>")),
                            tags$ul(
                              tags$li("Changepoint prior scale"),
                              tags$li("Seasonality types (yearly, weekly, daily)"),
                              tags$li("Holiday effects")
                            ),
                            
                            tags$div(class = "note", 
                                     tags$p(HTML("<strong>Pro Tip:</strong> Start with automatic methods (auto.arima, auto ETS) to get baseline results, then experiment with manual parameters if needed for refinement."))
                            )
                   ),
                   
                   # Results Tab
                   tags$div(id = "results", class = "sub-section",
                            tags$h3("Results Tab"),
                            tags$p("After running a forecast, the Results tab provides comprehensive tools to analyze and interpret your predictions."),
                            
                            tags$h4("Performance Metrics"),
                            tags$ul(
                              tags$li(HTML("<strong>MAE (Mean Absolute Error):</strong> Average absolute difference between forecasted and actual values. Lower is better.")),
                              tags$li(HTML("<strong>RMSE (Root Mean Square Error):</strong> Root of average squared differences, giving more weight to larger errors. Lower is better.")),
                              tags$li(HTML("<strong>MAPE (Mean Absolute Percentage Error):</strong> Percentage representation of error relative to actual values. Lower is better."))
                            ),
                            
                            tags$h4("Forecast Visualization"),
                            tags$p("The main visualization shows your forecast alongside historical data:"),
                            tags$ul(
                              tags$li(HTML("<strong>Plot Type options:</strong> Choose between Line, Line with Points, or Area")),
                              tags$li(HTML("<strong>Prediction Intervals:</strong> Toggle to show/hide the forecast uncertainty range")),
                              tags$li(HTML("<strong>Interactive features:</strong> Hover for exact values, zoom, pan, and download as image"))
                            ),
                            
                            tags$div(class = "note", 
                                     tags$p(HTML("<strong>Interpretation Guide:</strong> Generally, a MAPE below 10% indicates excellent forecast accuracy, 10-20% is good, 20-30% is acceptable, and above 30% suggests the forecast may need improvement."))
                            )
                   ),
                   
                   # Diagnostics Tab
                   tags$div(id = "diagnostics", class = "sub-section",
                            tags$h3("Diagnostics Tab"),
                            tags$p("The Diagnostics tab offers powerful tools to evaluate model quality, understand limitations, and compare different forecasting approaches."),
                            
                            tags$h4("Residual Analysis"),
                            tags$p("Residuals are the differences between actual and fitted values. Ideally, residuals should be random with no pattern:"),
                            tags$ul(
                              tags$li(HTML("<strong>Time Series plot:</strong> Shows residuals over time - look for random scattering around zero")),
                              tags$li(HTML("<strong>Histogram:</strong> Displays distribution - ideally bell-shaped and centered at zero")),
                              tags$li(HTML("<strong>QQ Plot:</strong> Tests for normality - points should follow the diagonal line")),
                              tags$li(HTML("<strong>ACF:</strong> Autocorrelation function - values should stay within confidence bands"))
                            ),
                            
                            tags$h4("Model Comparison"),
                            tags$p("Compare different forecasting methods to find the best one for your data:"),
                            tags$ol(
                              tags$li("Select which models to compare (ARIMA, ETS, Prophet)"),
                              tags$li("Click 'Run Comparison' to perform cross-validation"),
                              tags$li("View comparison metrics and error distributions to identify the best performer")
                            ),
                            
                            tags$div(class = "warning", 
                                     tags$p(HTML("<strong>Advanced Users:</strong> The diagnostics tab is particularly valuable for statistical analysts and data scientists who need to understand model assumptions and limitations."))
                            )
                   )
          ),
          
          # FAQ
          tags$div(id = "faq", class = "section",
                   tags$h2("Frequently Asked Questions"),
                   
                   tags$div(class = "faq-item",
                            tags$h4("Which forecasting method should I choose?"),
                            tags$p(HTML("
                          <strong>ARIMA:</strong> Best for data with clear trends and/or seasonality. Works well with stationary data or after applying differencing.<br>
                          <strong>Exponential Smoothing:</strong> Excellent for data with trend and seasonality, especially when recent observations should have more weight than older ones.<br>
                          <strong>Prophet:</strong> Ideal for business time series with multiple seasonal patterns, holidays, and outliers. Very robust to missing data and shifts in trend.
                          "))
                   ),
                   
                   tags$div(class = "faq-item",
                            tags$h4("How do I interpret the forecast performance metrics?"),
                            tags$p(HTML("
                          <strong>MAE (Mean Absolute Error):</strong> Average absolute difference between forecasted and actual values. Measured in the same units as your data. Lower is better.<br>
                          <strong>RMSE (Root Mean Square Error):</strong> Similar to MAE but gives more weight to large errors. Also in the same units as your data. Lower is better.<br>
                          <strong>MAPE (Mean Absolute Percentage Error):</strong> Average percentage difference between forecasted and actual values. Generally, MAPE < 10% is excellent, 10-20% is good, 20-30% is acceptable, and >30% may indicate poor forecast quality.
                          "))
                   ),
                   
                   tags$div(class = "faq-item",
                            tags$h4("How far ahead can I forecast reliably?"),
                            tags$p("The reliable forecast horizon depends on several factors including data quality, historical data amount, series stability, and forecast method. As a rule of thumb, forecast accuracy typically deteriorates the further into the future you predict. For most business time series, forecasts beyond 6-12 periods carry increasing uncertainty.")
                   ),
                   
                   tags$div(class = "faq-item",
                            tags$h4("How should I handle outliers in my data?"),
                            tags$p(HTML("
                          First use 'Highlight Outliers' in the Preprocessing tab visualization to see outliers, then choose an approach:<br>
                          <strong>Keep:</strong> Use when outliers represent genuine events you want the model to learn from<br>
                          <strong>Remove:</strong> Use when outliers are data errors or extremely unusual events<br>
                          <strong>Replace with Mean/Median:</strong> Good middle-ground approach<br>
                          <strong>Winsorize:</strong> Caps extreme values at percentile boundaries while preserving direction
                          "))
                   )
          ),
          
          # Best Practices
          tags$div(id = "best-practices", class = "section",
                   tags$h2("Tips for Effective Forecasting"),
                   
                   tags$h4("Data Preparation"),
                   tags$ul(
                     tags$li(HTML("<strong>Sufficient history:</strong> Aim for at least 3-4 times more historical data than your forecast horizon")),
                     tags$li(HTML("<strong>Consistent frequency:</strong> Try to maintain the same observation frequency throughout your dataset")),
                     tags$li(HTML("<strong>Handle outliers carefully:</strong> Identify and address outliers before forecasting")),
                     tags$li(HTML("<strong>Address missing values:</strong> Use appropriate imputation methods based on your data patterns"))
                   ),
                   
                   tags$h4("Method Selection"),
                   tags$ul(
                     tags$li(HTML("<strong>Try multiple methods:</strong> Use the Model Comparison feature to test different approaches")),
                     tags$li(HTML("<strong>Consider data characteristics:</strong> Match the method to your data's patterns (trend, seasonality, etc.)")),
                     tags$li(HTML("<strong>Start simple:</strong> Begin with automatic methods before fine-tuning parameters")),
                     tags$li(HTML("<strong>Evaluate statistically:</strong> Use the Diagnostics tab to ensure model assumptions are valid"))
                   ),
                   
                   tags$h4("Common Pitfalls to Avoid"),
                   tags$ul(
                     tags$li(HTML("<strong>Overfitting:</strong> Adding too many parameters can make your model fit historical data well but perform poorly on future data")),
                     tags$li(HTML("<strong>Ignoring Diagnostics:</strong> Poor residual patterns often indicate an inadequate model")),
                     tags$li(HTML("<strong>Too Long Horizon:</strong> Forecasting too far into the future leads to unreliable predictions")),
                     tags$li(HTML("<strong>Disregarding Outliers:</strong> Failing to properly address outliers can severely distort forecasts"))
                   )
          ),
          
          # Methods & Terminology
          tags$div(id = "methods", class = "section",
                   tags$h2("Methods & Terminology"),
                   
                   tags$h4("ARIMA"),
                   tags$p(HTML("ARIMA (Auto-Regressive Integrated Moving Average) models combine three components:")),
                   tags$ul(
                     tags$li(HTML("<strong>AR (Auto-Regressive):</strong> Uses the relationship between an observation and previous observations")),
                     tags$li(HTML("<strong>I (Integrated):</strong> Applies differencing to make the time series stationary")),
                     tags$li(HTML("<strong>MA (Moving Average):</strong> Uses the relationship between an observation and residual errors from a moving average model"))
                   ),
                   
                   tags$h4("Exponential Smoothing"),
                   tags$p(HTML("Exponential Smoothing applies exponentially decreasing weights to past observations. Different variations handle different patterns:")),
                   tags$ul(
                     tags$li(HTML("<strong>Simple Exponential Smoothing:</strong> For data with no clear trend or seasonality")),
                     tags$li(HTML("<strong>Holt's Linear Method:</strong> For data with trend but no seasonality")),
                     tags$li(HTML("<strong>Holt-Winters Method:</strong> For data with both trend and seasonality"))
                   ),
                   
                   tags$h4("Prophet"),
                   tags$p(HTML("Prophet is a procedure for forecasting time series data developed by Facebook. Key features include:")),
                   tags$ul(
                     tags$li("Handles missing data and outliers automatically"),
                     tags$li("Detects trend changes with automatic changepoint detection"),
                     tags$li("Accommodates multiple seasonal patterns"),
                     tags$li("Incorporates holidays and special events")
                   ),
                   
                   tags$h4("Key Terms"),
                   tags$dl(
                     tags$dt("Seasonality"),
                     tags$dd("Regular pattern that repeats over a fixed period (daily, weekly, monthly, etc.)."),
                     
                     tags$dt("Trend"),
                     tags$dd("Long-term increase or decrease in the data."),
                     
                     tags$dt("Stationarity"),
                     tags$dd("Property where statistical properties like mean and variance don't change over time."),
                     
                     tags$dt("Residuals"),
                     tags$dd("Differences between observed values and values predicted by a model."),
                     
                     tags$dt("Cross-Validation"),
                     tags$dd("Technique to evaluate model performance by testing it on multiple subsets of data.")
                   )
          ),
          
          
          # Footer
          tags$div(class = "footer",
                   tags$p("Lucent Time Series Forecasting Application © 2025"),
                   tags$p("Developed by OMNISIGHT ANALYTICS by Forefront Consulting"),
                   tags$p(paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
          )
        )
      )
      
      # Write HTML to temporary file
      html_content_string <- as.character(html_content)
      writeLines(html_content_string, temp_html)
      
      # Convert HTML to PDF
      tryCatch({
        # First attempt with pagedown
        pagedown::chrome_print(temp_html, 
                               output = file,
                               options = list(
                                 margin = list(
                                   top = "0.75in",
                                   right = "0.75in", 
                                   bottom = "0.75in", 
                                   left = "0.75in"
                                 ),
                                 printBackground = TRUE
                               )
        )
      }, error = function(e) {
        # Fallback to webshot2 if pagedown fails
        webshot2::webshot(temp_html, 
                          file = file,
                          delay = 2, 
                          vwidth = 900,
                          vheight = 1200)
      })
      
      # Clean up temp file
      unlink(temp_html)
      
      # Remove modal
      removeModal()
      
      # Show success notification
      showNotification("Help PDF generated successfully!", type = "message", duration = 5)
    }
  )
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
}

# To run this minimal app:



shinyApp(ui = ui, server = server)