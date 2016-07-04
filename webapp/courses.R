
getListOfUniversities <- function () {
  unis <- list( 
                "Choose a university" = "prompt",
                "University of Southampton" = "soton"
              )
  return (unis)
}

getListOfCourses <- function (uni) {
  if (uni == "soton") {
    courses <- list(
                    "Choose a course" = "prompt",
                    "Developing Your Research Project" = "dyrp",
                    "Archaelogy of Portus" = "portus",
                    "Exploring our Oceans" = "oceans",
                    "Digital Marketing" = "marketing",
                    "Understanding Language" = "language",
                    "Contract Management" = "contract",
                    "Shipwrecks" = "shipwrecks",
                    "Web Science" = "ws", 
                    "Battle of Waterloo" = "watloo"
                   )
  }
}

getNumberOfRuns <- function (course) {
  if (course == "dyrp") {
    return (c(1, 2, 3))
  } else if (course == "portus") {
    return (c(1, 2, 3))
  } else if (course == "oceans") {
    return (c(1, 2))
  } else if (course == "marketing") {
    return (1)
  } else if (course == "language") {
    return (c(1, 2))
  } else if (course == "contract") {
    return (1)
  } else if (course == "shipwrecks") {
    return (1)
  } else if (course == "ws") {
    return (c(1, 2, 3))
  } else if (course == "watloo") {
    return (1)
  } 
}

getCourseDates <- function (course, run) {
  if (course == "dyrp") {
    start <- as.POSIXct(getDYRPStartDate(run))
    length <- getDYRPWeeks()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }else if (course == "portus") {
    start <- as.POSIXct(getPortusStartDate(run))
    length <- getPortusWeeks()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }else if (course == "oceans") {
    start <- as.POSIXct(getOceansStartDate(run))
    length <- getOceansWeeks()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }else if (course == "marketing") {
    start <- as.POSIXct(getMarketingStartDate(run))
    length <- getMarktingWeeks()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }else if (course == "language") {
    start <- as.POSIXct(getMarketingStartDate(run))
    length <- getMarktingWeeks()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }else if (course == "contract") {
    start <- as.POSIXct(getContractWeeks(run))
    length <- getContractStartDate()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }else if (course == "shipwrecks") {
    start <- as.POSIXct(getShipwrecksStartDate(run))
    length <- getShipwrecksWeeks()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }else if (course == "ws") {
    start <- as.POSIXct(getWSStartDate(run))
    length <- getWSWeeks()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }else if (course == "watloo") {
    start <- as.POSIXct(getWatlooStartDate(run))
    length <- getWatlooWeeks()
    end <- start + length * 7 * 24 * 60 * 60
    return (list(start, end, length))
  }
}

getDYRPStartDate <- function (courseRun) {
  if (courseRun == 1) {
    return ("2014-07-07")
  }else if (courseRun == 2) {
    return ("2014-09-15")
  }else if (courseRun == 3) {
    return ("2015-06-22")
  }
}

getDYRPWeeks <- function () {
  return (8)
}

getPortusStartDate <- function (courseRun) {
  if (courseRun == 1) {
    return ("2014-05-19")
  }else if (courseRun == 2) {
    return ("2015-01-26")
  }else if (courseRun == 3) {
    return ("2015-06-15")
  }
}

getPortusWeeks <- function () {
  return (6)
}

getWatlooStartDate <- function (courseRun) {
  if (courseRun == 1) {
    return ("2015-06-08")
  }
}

getWatlooWeeks <- function () {
  return (3)
}

getOceansStartDate <- function (courseRun) {
  if (courseRun == 1) {
    return ("2014-02-03")
  }else if (courseRun == 2) {
    return ("2014-10-27")
  }
} 

getOceansWeeks <- function () {
  return (6)
}

getMarketingStartDate <- function (courseRun) {
  if (courseRun == 1){
    return ("2014-10-13")  
  }
}

getMarktingWeeks <- function () {
  return (3)
}

getLanguageStartDate <- function (courseRun) {
  if (courseRun == 1) {
    return ("2014-11-17")
  }else if (courseRun == 2) {
    return ("2015-04-20")
  }
}

getLanguageWeeks <- function () {
  return (4)
}

getContractStartDate <- function (courseRun) {
  if (courseRun == 1) {
    return ("2015-04-27")
  }
}

getContractWeeks <- function () {
  return (3)
}

getShipwrecksStartDate <- function (courseRun) {
  if (courseRun == 1) {
    return ("2014-10-06")
  }
}

getShipwrecksWeeks <- function () {
  return (4)
}

getWSStartDate <- function (courseRun) {
  if (courseRun == 1) {
    return ("2013-11-11")
  }else if (courseRun == 2) {
    return ("2014-02-10")
  }else if (courseRun == 3) {
    return ("2014-10-06")
  }
}

getWSWeeks <- function () {
  return (6)
}


















