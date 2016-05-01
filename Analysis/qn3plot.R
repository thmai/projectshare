library(ggplot2)
library(stringr)
library(ade4)

raw <- read.csv("raw.csv", stringsAsFactors = F, header = T)

# Clean the raw column X3.g
CleanOthers <- function(x) {
  if (is.na(x)) return(NA)
  
  # Change to trim, lower case
  x <- str_trim(x)
  x <- str_to_lower(x)
 
  # Classify NA cases 
  na.cases <- c("0", "1", "冇", "無", "沒有", "no", "n/a", "none", "10", "9",
                "voa1", "mirror", "abc", "香島", "2", "3", "/", "", "／",
                "nothing", "car", "sunday", "classified post 1",
                "the plymoth fab")
  if (x %in% na.cases) return(NA)
  
  # Classify South China Morning Post
  scmp.cases <- c("south china morning psot", "south china morning post",
                  "scmp", "young post")
  if (x %in% scmp.cases) return("SCMP")
  
  # Classify MingPao
  mp.cases <- c("明報")
  if (x %in% mp.cases) return("MingPao")
  
  # Classify DailyMail
  dm.cases <- c("每日郵報")
  if (x %in% dm.cases) return("DailyMail")
  
  # Classify The Standard newspaper
  ts.cases <- c("the standard", "虎報")
  if (x %in% ts.cases) return("TheStandard")
  
  # Classify Apple Daily
  ad.cases <- c("apple(every day)", "apple", "apple daily", "頭條,蘋果", "蘋果")
  if (x %in% ad.cases) return("AppleDaily")
  
  # Classify Oriental Daily
  od.cases <- c("東方日報", "東方")
  if (x %in% od.cases) return("OrientalDaily")
  
  # Classify Sing Tao Daily
  st.cases <- c("星島日報")
  if (x %in% st.cases) return("SingTaoDaily")
  
  # Classify Liberty Times
  lt.cases <- c("自由時報")
  if (x %in% lt.cases) return("LibertyTimes")
  
  # Classify CNN
  cnn.cases <- c("cnn apps", "cnn")
  if (x %in% cnn.cases) return("CNN")
  
  # Classify Japanese Newspaper
  jp.cases <- c("日本報紙")
  if (x %in% jp.cases) return("JapaneseNewspaper")
  
  # Classify Business Weekly
  bw.cases <- c("經濟達人")
  if (x %in% bw.cases) return("BusinessWeekly")
  
  # Classify Morning Paper (Taiwan)
  tm.cases <- c("中華早報")
  if (x %in% tm.cases) return("MorningPaperTW")
  
  # Classify Other Intl
  intl.cases <- c("time", "timeshk,timeslondon",
                  "the economist / good howekeephy / times / readers digeot",
                  "the times", "timesmag", "der spiegel明鏡", "bloomberg")
  if (x %in% intl.cases) return("OtherIntl")
  
  # Return x if no matching case
  x
}
X3.g.cleaned <- sapply(raw$X3.g, CleanOthers)

df <- read.csv("clean_data.csv", stringsAsFactors = F, header = T)
qn3 <- c('X3.a', 'X3.b', 'X3.c', 'X3.d', 'X3.e', 'X3.f')
df.qn3 <- df[, qn3]
df.qn3$X3.g <- X3.g.cleaned

# Rename column names
colnames(df.qn3) <- c("BBC", "FinancialTimes", "NewYorkTimes", "TheGuardian",
                      "WSJ", "SCMP", "Others")

# Merge SCMP column and SCMP from Others column.
DidReadSCMP <- function(row) {
  row[is.na(row)] <- 0
  scmp <- as.numeric(row["SCMP"])
  others <- as.character(row["Others"])
  
  if (scmp > 0) return(1)
  else return(as.numeric(others == "SCMP"))
}
df.qn3[["SCMP"]] <- apply(df.qn3, 1, DidReadSCMP)

# Convert to 1s and 0s (Did read = 1, did not read = 0)
features <- colnames(df.qn3)[1:6]
for (f in features) df.qn3[[f]] <- ifelse(df.qn3[[f]] > 0, 1, 0)

# Remove SCMP from others, perform one-hot encoding
df.qn3[which(df.qn3$Others == "SCMP"), ]$Others <- NA
df.qn3 <- cbind(df.qn3, acm.disjonctif(df.qn3['Others']))
df.qn3$Others <- NULL

# Impute missing values with 0s (14 rows to impute)
df.qn3[is.na(df.qn3)] <- 0

# Create newspaper categories
national <- c("SCMP", "Others.AppleDaily", "Others.BusinessWeekly", "Others.DailyMail",
              "Others.LibertyTimes", "Others.MingPao", "Others.MorningPaperTW",
              "Others.OrientalDaily", "Others.SingTaoDaily", "Others.TheStandard")
international <- setdiff(colnames(df.qn3), national)

# Group into National Only, International Only, Both (National + International), None
ReadingCategory <- function(row) {
  read.national <- sum(row[national])
  read.intl     <- sum(row[international])
  
  if(read.national > 0 && read.intl > 0) return("Both")
  else if (read.national > 0) return("National Only")
  else if (read.intl > 0) return("International Only")
  else "None"
}
df.qn3$ReadingCategory <- apply(df.qn3, 1, ReadingCategory)

# Sum by category
NationalSources <- function(row) sum(as.numeric(row[national]))
IntlSources <- function(row) sum(as.numeric(row[international]))
TotalSources <- function(row) sum(as.numeric(row[c("NationalSources","IntlSources")]))
df.qn3$NationalSources <- apply(df.qn3, 1, NationalSources)
df.qn3$IntlSources <- apply(df.qn3, 1, IntlSources)
df.qn3$TotalSources <- apply(df.qn3, 1, TotalSources)

# Define reusable functions
ConcatWords <- function(row) paste0(as.character(na.omit(row)), collapse = ' & ')
BreakSentence <- function(x) {
  if (nchar(x) > 25) {
    space.indexes <- str_locate_all(x, " ")[[1]][,1]
    space.index <- space.indexes[length(space.indexes)/2 + 1]
    str_sub(x, space.index, space.index) <- "\n"
  }
  x
}
FactorAndReorder <- function(v) { 
  fac <- factor(v, levels=names(sort(table(v), decreasing = T)))
  levels(fac) <- sapply(levels(fac), BreakSentence)
  fac
}
GGBarCount <- function() geom_text(stat='count', aes(label=..count..), vjust=-1)
GGTiltXLabel <- function() theme(axis.text.x = element_text(angle = 45, hjust = 1))
GGBreakdown <- function(df) ggplot(df, aes(Breakdown)) + geom_bar() + GGBarCount()

# Plot graph
ggplot(df.qn3, aes(ReadingCategory)) + geom_bar(aes(fill = factor(TotalSources))) +
  GGBarCount() + ggtitle("Breakdown of People Who Read Newspapers") + scale_fill_discrete(name="Number of Different\nNewspapers Read")

# Breakdown of National Only
df.qn3.national <- df.qn3[which(df.qn3$ReadingCategory == "National Only"), national]
for (col in national) df.qn3.national[[col]] <- ifelse(df.qn3.national[[col]] == 1, col, NA)
df.qn3.national$Breakdown <- FactorAndReorder(apply(df.qn3.national, 1, ConcatWords))
GGBreakdown(df.qn3.national) + ggtitle("Breakdown of People Who Read National Newspaper Only")

# Breakdown of International Only
df.qn3.intl <- df.qn3[which(df.qn3$ReadingCategory == "International Only"), international]
for (col in international) df.qn3.intl[[col]] <- ifelse(df.qn3.intl[[col]] == 1, col, NA)
df.qn3.intl$Breakdown <-  FactorAndReorder(apply(df.qn3.intl, 1, ConcatWords))
GGBreakdown(df.qn3.intl) + GGTiltXLabel() + ggtitle("Breakdown of People Who Read International Newspaper Only")

# Breakdown of Both (National & International)
df.qn3.both <- df.qn3[which(df.qn3$ReadingCategory == "Both"), c(national, international)]
for (col in colnames(df.qn3.both)) df.qn3.both[[col]] <- ifelse(df.qn3.both[[col]] == 1, col, NA)
df.qn3.both$Breakdown <- FactorAndReorder(apply(df.qn3.both, 1, ConcatWords))
GGBreakdown(df.qn3.both) + GGTiltXLabel() + ggtitle("Breakdown of People Who Read Both National and International Newspaper")
