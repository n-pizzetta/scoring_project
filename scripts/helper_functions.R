# Function to format the dataframes displayed
styled_dt <- function(df, n=5) {
  DT::datatable(df, 
                extensions = 'Buttons',
                rownames = FALSE,
                class = 'dataTables_wrapper',
                options = list(
                  scrollX = TRUE, 
                  pageLength = n,
                  dom = 'Bfrtip',
                  buttons = c('copy', 'csv', 'excel')
                ))
}
