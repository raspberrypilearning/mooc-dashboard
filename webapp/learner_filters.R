library(reshape2)

#import pre-course survey csv data
getPreCourseData <- function (filename) {
  #load the pre-course survey data using nrows=0 to include the second row header
  pre_course_data <- read.csv(filename, nrows = 0,
                              na.strings = c("Unknown", ""),  sep = ",")
  return (pre_course_data)
}
#check whether the survey has data for how the learners found out about the course
checkHasHowFoundCourse <- function (data) {
  if (data[1,1] == "TRUE") {
    return (TRUE)
  }
  return (FALSE)
}

#find learners based on how they found out about the course
getLearnersByHowFoundCourse <- function (data) {
  data <- data[-1,]
  mdata <- melt(data, id = c("learner_id"), na.rm = TRUE)
  mdata <- subset(mdata, variable == "how_found_course")
  pivot <- dcast(mdata, value ~ ., length)
  mdata <- mdata[c("learner_id", "value")]
  colnames(mdata)[2] <- "how_found_course"
  colnames(pivot) <- c("how_found_course", "count")
  return (list(mdata, pivot))
}

#find learners based on what they hope to get out of the course
getLearnersByHopeGetFromCourse <- function (data) {
  start <- which(colnames(data) == "hope_get_course") 
  end <- which(colnames(data) == "learning_methods") - 1
  stripped <- cbind(data[,start:end], data$learner_id)
  colnames(stripped) <- unlist(stripped[1,])
  colnames(stripped)[length(stripped)] <- "learner_id"
  stripped <- stripped[2:nrow(stripped),]
  mdata <- melt(stripped, id = c("learner_id"), na.rm = TRUE)
  pivot <- dcast(mdata, variable ~ ., length)
  mdata <- mdata[c("learner_id", "variable")]
  colnames(mdata)[2] <- "hope_get_course"
  colnames(pivot) <- c("hope_get_course", "count")
  return (list(mdata, pivot))
}

#prepare the data for filtering on desired methods of learning
getLearnersByLearningMethods <- function (data) {
  #extract the necessary columns
  start <- which(colnames(data) == "learning_methods")
  end <- which(colnames(data) == "interested_subjects") - 1
  stripped <- data[,start:end]
  #rename the columns for easier manipulation
  names(stripped) <- unlist(stripped[1,])
  #add the learner id column
  stripped$learner_id <- data$learner_id
  #removes the names row
  stripped <- stripped[-1,]
  mdata <- melt(stripped, id = c("learner_id"), na.rm = TRUE)
  pivot <- dcast(mdata, variable + value~ ., length)
  colnames(mdata)[2:3] <- c("learning_method", "degree")
  colnames(pivot) <- c("learning_method", "degree", "count")
  return (list(mdata, pivot))
}

#prepare the data for filtering based on interested subject areas
getLearnersByInterestedSubjects <- function (data) {
  #extract the necessary columns
  start <- which(colnames(data) == "interested_subjects")
  end <- which(colnames(data) == "previous_online_course") - 1
  stripped <- data[,start:end]
  #rename the columns for easier manipulation
  names(stripped) <- unlist(stripped[1,])
  #add the learner id column
  stripped$learner_id <- data$learner_id
  #removes the names row
  stripped <- stripped[-1,]
  mdata <- melt(stripped, id=c("learner_id"), na.rm = TRUE)
  mdata <- mdata[,1:2]
  pivot <- dcast(mdata, variable ~ ., length)
  colnames(mdata)[2] <- "subject"
  colnames(pivot) <- c("subject", "count")
  return (list(mdata, pivot))
}


#filter learners based on the type of online course they have taken before
getLearnersByPastOnlineCourse <- function (data) {
  #extract the necessary columns
  start <- which(colnames(data) == "previous_online_course")
  end <- which(colnames(data) == "learning_place") - 1
  stripped <- data[,start:end]
  #rename the columns for easier manipulation
  names(stripped) <- unlist(stripped[1,])
  #add the learner id column
  stripped$learner_id <- data$learner_id
  #removes the names row
  stripped <- stripped[-1,]
  mdata <- melt(stripped, id=c("learner_id"), na.rm = TRUE)
  mdata <- mdata[,1:2]
  pivot <- dcast(mdata, variable ~ ., length)
  colnames(mdata)[2] <- "previous_online_course"
  colnames(pivot) <- c("previous_online_course", "count")
  return (list(mdata, pivot))
}

#filter learners based on where they expect to do the course
getLearnersByExpectedLearningPlace <- function (data) {
  #extract the necessary columns
  start <- which(colnames(data) == "learning_place")
  end <- which(colnames(data) == "country") - 1
  stripped <- data[,start:end]
  #rename the columns for easier manipulation
  names(stripped) <- unlist(stripped[1,])
  #add the learner id column
  stripped$learner_id <- data$learner_id
  #removes the names row
  stripped <- stripped[-1,]
  #melt the data
  mdata <- melt(stripped, id=c("learner_id"), na.rm = TRUE)
  mdata <- mdata[,1:2]
  pivot <- dcast(mdata, variable ~ ., length)
  colnames(mdata)[2] <- "learning_place"
  colnames(pivot) <- c("learning_place", "count")
  return (list(mdata, pivot))
}

#filter learners based on country of residence
getLearnersByCountry <- function (data) {
  stripped <- cbind(data.frame(data$country), data.frame(data$learner_id))[-1,]
  colnames(stripped) <- c("country", "learner_id")
  mdata <- melt(stripped, id = c("learner_id"), na.rm = TRUE)
  mdata <- cbind(mdata[1], mdata[3])
  pivot <- dcast(mdata, value ~ ., length)
  pivot <- pivot[-1,]
  colnames(mdata)[2] <- "country"
  colnames(pivot) <- c("country", "learners")
  return (list(mdata, pivot))
}

#filter learners by age group
getLearnersByAge <- function (data) {
  stripped <- cbind(data.frame(data$age_range), data.frame(data$learner_id))[-1,]
  colnames(stripped) <- c("age", "learner_id")
  mdata <- melt(stripped, id = c("learner_id"), na.rm = TRUE)
  mdata <- cbind(mdata[1], mdata[3])
  pivot <- dcast(mdata, value ~ ., length)
  colnames(mdata)[2] <- "age"
  colnames(pivot) <- c("age", "count")
  return (list(mdata, pivot))
}


#filter learners by gender
getLearnersByGender <- function (data) {
  stripped <- cbind(data.frame(data$gender), data.frame(data$learner_id))[-1,]
  colnames(stripped) <- c("gender", "learner_id")
  mdata <- melt(stripped, id = c("learner_id"), na.rm = TRUE)
  mdata <- cbind(mdata[1], mdata[3])
  pivot <- dcast(mdata, value ~ ., length)
  colnames(mdata)[2] <- "gender"
  colnames(pivot) <- c("gender", "count")
  return (list(mdata, pivot))
}

#filter learners by employment status
getLearnersByEmploymentStatus <- function (data) {
  stripped <- cbind(data.frame(data$employment_status), data.frame(data$learner_id))[-1,]
  colnames(stripped) <- c("employment_status", "learner_id")
  mdata <- melt(stripped, id = c("learner_id"), na.rm = TRUE)
  mdata <- cbind(mdata[1], mdata[3])
  pivot <- dcast(mdata, value ~ ., length)
  colnames(mdata)[2] <- "employment_status"
  colnames(pivot) <- c("employment_status", "count")
  return (list(mdata, pivot))
}

#filter learners by employment area
getLearnersByEmploymentArea <- function (data) {
  stripped <- cbind(data.frame(data$employment_area), data.frame(data$learner_id))[-1,]
  colnames(stripped) <- c("employment_area", "learner_id")
  mdata <- melt(stripped, id = c("learner_id"), na.rm = TRUE)
  mdata <- cbind(mdata[1], mdata[3])
  pivot <- dcast(mdata, value ~ ., length)
  colnames(mdata)[2] <- "employment_area"
  colnames(pivot) <- c("employment_area", "count")
  return (list(mdata, pivot))
}

#filter learners based on level of education
getLearnersByDegreeLevel <- function (data) {
  stripped <- cbind(data.frame(data$highest_education_level), data.frame(data$learner_id))[-1,]
  colnames(stripped) <- c("highest_education_level", "learner_id")
  mdata <- melt(stripped, id = c("learner_id"), na.rm = TRUE)
  mdata <- cbind(mdata[1], mdata[3])
  pivot <- dcast(mdata, value ~ ., length)
  colnames(mdata)[2] <- "degree"
  colnames(pivot) <- c("degree", "count")
  return (list(mdata, pivot))
}

