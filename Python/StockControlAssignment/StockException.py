''' Author: Catherine Boothman
    Student Number: D12127081

    Own set of defined exceptions that may occur due to wrong input '''


# -------------------------------------------------------------------------------------------------------------

import datetime

# -------------------------------------------------------------------------------------------------------------

class warehouseException(Exception):
    ''' warehouse number has to be between 1 to 4 '''
    def __init__(self, arg):
        self.arg = arg
        timeNow = datetime.datetime.now().strftime("%d %B %Y, %H:%M:%S")
        # open error log file and append error message to the end
        logFile = open("errorLog.txt", "a")
        errorMessage = "%s: Error in %s - warehouseNumber is out of range.\n" %(timeNow, self.arg)
        logFile.write(errorMessage)
        logFile.close()

class  stockItemAddedException(Exception):
    ''' stock item has already been added to the file '''
    def __init__(self, arg):
        self.arg = arg
        timeNow = datetime.datetime.now().strftime("%d %B %Y, %H:%M:%S")
        # open error log file and append error message to the end
        logFile = open("errorLog.txt", "a")
        errorMessage = "%s: Error in %s - stock item already exists.\n" %(timeNow, self.arg)
        logFile.write(errorMessage)
        logFile.close()

class invalidClientException(Exception):
    ''' invalid client name '''
    def __init__(self, arg):
        self.arg = arg
        timeNow = datetime.datetime.now().strftime("%d %B %Y, %H:%M:%S")
        # open error log file and append error message to the end
        logFile = open("errorLog.txt", "a")
        errorMessage = "%s: Error in %s - invalid client name.\n" %(timeNow, self.arg)
        logFile.write(errorMessage)
        logFile.close()

class invalidGenreException(Exception):
    ''' invalid genre selected '''
    def __init__(self, arg):
        self.arg = arg
        timeNow = datetime.datetime.now().strftime("%d %B %Y, %H:%M:%S")
        # open error log file and append error message to the end
        logFile = open("errorLog.txt", "a")
        errorMessage = "%s: Error in %s - invalid genre selected.\n" %(timeNow, self.arg)
        logFile.write(errorMessage)
        logFile.close()

class stockExsitsException(Exception):
    ''' stock item not in database '''
    def __init__(self, arg):
        self.arg = arg
        timeNow = datetime.datetime.now().strftime("%d %B %Y, %H:%M:%S")
        # open error log file and append error message to the end
        logFile = open("errorLog.txt", "a")
        errorMessage = "%s: Error in %s - stock item does not exist in database.\n" %(timeNow, self.arg)
        logFile.write(errorMessage)
        logFile.close()





