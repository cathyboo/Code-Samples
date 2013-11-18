''' Author: Catherine Boothman
    Student Number: D12127081
    
    Graphical User Interface for user to input new inventory items to the system. '''


# --------------------------------------------------- First GUI ---------------------------------------------------

# First screen allows the user to either load a .csv file containg a number of new stock items 
# or manually add either a Book Item or a CD Item via a button for each one

# tkinter is one of the few modules where it is not only safe to import everything but it is recommended
from Tkinter import *
# file browser to get filename of .csv file to load
from tkFileDialog import askopenfilename
from CDItem import *
from BookItem import *
from StockRepository import *
import datetime
import random
from StockException import stockExsitsException


# ----------------------------------------------- Defined Functions -----------------------------------------------

def addStockToDB():
    # get text entries to add stock item
    client = cliName.get()

    # add a book
    if (client != "") and (txtABT.get() != "") and (txtABA.get() != ""):
        title = txtABT.get()
        author = txtABA.get()
        date = txtABD.get()
        if date == "":
            date = datetime.datetime.now().strftime("%d-%m-%Y")
        genre = txtABG.get()
        if genre == "":
            genre = "undefined"
        numOfCopies = txtABN.get()
        pricePerUnit = txtABP.get()
        warehouseNum = txtABW.get()
        if warehouseNum == "":
            warehouseNum = random.randint(1,5)
        bookParam1 = [client, title, author, date, genre, numOfCopies, pricePerUnit, warehouseNum]
        book1 = BookItem(bookParam1)
        manageBook = StockRepository()
        manageBook.enterStock(book1)
        bookID = book1.getUniqueID()
        storeCost = book1.calcStorageCost()
        print "%s book item added to stock with ID of %d at a cost of %.2f" %(title, bookID, storeCost)

    # add a CD
    if (client != "") and (txtACT.get() != "") and (txtACA.get() != ""):
        title = txtACT.get()
        artist = txtACA.get()
        date = txtACD.get()
        if date == "":
            date = datetime.datetime.now().strftime("%d-%m-%Y")
        genre = txtACG.get()
        if genre == "":
            genre = "undefined"
        numOfCopies = txtACN.get()
        pricePerUnit = txtACP.get()
        warehouseNum = txtACW.get()
        if warehouseNum == "":
            warehouseNum = random.randint(1,5)
        cdParam1 = [client, title, artist, date, genre, numOfCopies, pricePerUnit, warehouseNum]
        cd1 = CDItem(cdParam1)
        manageCD = StockRepository()
        manageCD.enterStock(cd1)
        cdID = cd1.getUniqueID()
        storeCost = cd1.calcStorageCost()
        print "%s cd item added to stock with ID of %d, with a cost of %.2f" %(title, cdID, storeCost)



def removeStockFromDB():
    client = cliName.get()
    # the idea here is that using the client name and the cd / book title and creator the id is looked up
    # if more than one instance exist just one is deleted

    # remove a book
    if (client != "") and (txtRBT.get() != "") and (txtRBA.get() != ""):
        title = txtRBT.get()
        author = txtRBA.get()
        # default vlaues for to test if the have been updated
        bookID = 0
        # open the csv file to look up the book item
        try:
            stockFile = open("BuyNLargeStock.csv", "rU")
        except IOError:
            print "No database to delete stock from"
        else:
            # get rid of header line
            headerLine = stockFile.readline()
            for line in stockFile:
                line = line.strip("\n")
                params = line.split(",")
                stockID = int(params[0])
                stockClient = params[1]
                stockTitle = params[2]
                stockAuthor = params[3]
                stockFlag = params[10]
                if (client == stockClient) and (stockTitle == title) and (author == stockAuthor) and (stockFlag != "deleted"):
                    # stock exists to be deleted
                    bookID = stockID
                    date = params[4]
                    genre = params[5]
                    numOfCopies = int(params[6])
                    pricePerUnit = float(params[7])
                    warehouseNum = int(params[8])
            
            # create item if it exsits
            if bookID != 0:
                bookParam = [client, title, author, date, genre, numOfCopies, pricePerUnit, warehouseNum]
                book2 = BookItem(bookParam)
                book2.updateUniqueID(bookID)
                manageBook = StockRepository()
                manageBook.deleteStock(book2)
                print "Book deleted from stock"
            else:
                try:
                    raise stockExsitsException("buynlargeGUI.removeStockFromDB()")
                except stockExsitsException:
                    print "Book item does not exist to remove from database"
            
    # remove a cd
    if (client != "") and (txtRCT.get() != "") and (txtRCA.get() != ""):
        title = txtRCT.get()
        artist = txtRCA.get()
        # default vlaues for to test if the have been updated
        cdID = 0
        # open the csv file to look up the book item
        try:
            stockFile = open("BuyNLargeStock.csv", "rU")
        except IOError:
            print "No database to delete stock from"
        else:
            # get rid of header line
            headerLine = stockFile.readline()
            for line in stockFile:
                line = line.strip("\n")
                params = line.split(",")
                stockID = int(params[0])
                stockClient = params[1]
                stockTitle = params[2]
                stockArtist = params[3]
                stockFlag = params[10]
                if (client == stockClient) and (stockTitle == title) and (artist == stockArtist) and (stockFlag != "deleted"):
                    # stock exists to be deleted
                    cdID = stockID
                    date = params[4]
                    genre = params[5]
                    numOfCopies = int(params[6])
                    pricePerUnit = float(params[7])
                    warehouseNum = int(params[8])
            
            # create item if it exsits
            if cdID != 0:
                cdParam = [client, title, author, date, genre, numOfCopies, pricePerUnit, warehouseNum]
                cd2 = BookItem(bookParam)
                cd2.updateUniqueID(bookID)
                manageCD = StockRepository()
                manageCD.deleteStock(cd2)
                print "CD deleted from stock"
            else:
                try:
                    raise stockExsitsException("buynlargeGUI.removeStockFromDB()")
                except stockExsitsException:
                    print "CD item does not exist to remove from database"


# ------------------------------------------- End of Defined Functions --------------------------------------------


# main window GUI (mWin)
mWin = Tk()

# get screen size 
w = mWin.winfo_screenwidth()
h = mWin.winfo_screenheight()

w = (w / 100) * 90
h = (h / 100) * 90

# parameters of mWin
mWin.title("Buy N Large Stock Management")
# mWin.geometry("%dx%d" %(w,h))

# invisible frame to hold other frames and attach scrollbars too
frmMain = Frame(mWin, height = 300)

# client name selection from list box
cliName = StringVar(mWin)
comList = ["CD WoW", "Books Unlimited", "New Media"]

lblClient = Label(frmMain, text = "Select Company:")
opmClient = OptionMenu(frmMain, cliName, "CD WoW", "Books Unlimited", "New Media")


# -------------- Add Stock ---------------

# frame for adding stock
frmAddStock = LabelFrame(frmMain, text = "Add Stock", labelanchor = "nw")
fAS = frmAddStock 

# frame to manually add a book item
frmAddBook = LabelFrame(fAS, text = "Manually Add Book Item", labelanchor = "n")
fAB = frmAddBook

# entry requirements to add a book
lblABT = Label(fAB, text = "Book Title")
lblABA = Label(fAB, text = "Author")
lblABD = Label(fAB, text = "Published Date")
lblABG = Label(fAB, text = "Genre")
lblABN = Label(fAB, text = "Number of Copies")
lblABP = Label(fAB, text = "Price Per Unit")
lblABW = Label(fAB, text = "Warehouse Number")

# manual entry text boxes
txtABT = Entry(fAB, width = 15)
txtABA = Entry(fAB, width = 15)
txtABD = Entry(fAB, width = 15)
txtABG = Entry(fAB, width = 15)
txtABG.insert(0,"Fiction")
txtABN = Entry(fAB, width = 15)
txtABN.insert(0,1)
txtABP = Entry(fAB, width = 15)
txtABP.insert(0,9.99)
txtABW = Entry(fAB, width = 15)

# frame to manulally add a CD item
frmAddCD = LabelFrame(fAS, text = "Manually Add CD Item", labelanchor = "n")
fAC = frmAddCD

# entry requirement labels to add a CD
lblACT = Label(fAC, text = "CD Title")
lblACA = Label(fAC, text = "Artist")
lblACD = Label(fAC, text = "Date Released")
lblACG = Label(fAC, text = "Genre")
lblACN = Label(fAC, text = "Number of Copies")
lblACP = Label(fAC, text = "Price Per Unit")
lblACW = Label(fAC, text = "Warehouse Number")

# manual entry text boxes
txtACT = Entry(fAC, width = 15)
txtACA = Entry(fAC, width = 15)
txtACD = Entry(fAC, width = 15)
txtACG = Entry(fAC, width = 15)
txtACN = Entry(fAC, width = 15)
txtACN.insert(0,1)
txtACP = Entry(fAC, width = 15)
txtACP.insert(0,9.99)
txtACW = Entry(fAC, width = 15)

# Add Stock Button
btnAddStock = Button(fAS, text = "Add Stock Items", width = 15, height = 2, command = addStockToDB)


# -------------- Remove Stock ---------------

# frame for removing stock
frmRemoveStock = LabelFrame(frmMain, text = "Remove Stock", labelanchor = "nw")
fRS = frmRemoveStock

# frame to manually remove a book item
frmRemoveBook = LabelFrame(fRS, text = "Manually Remove Book Item", labelanchor = "n")
fRB = frmRemoveBook

# entry requirements to remove a book
lblRBT = Label(fRB, text = "Book Title")
lblRBA = Label(fRB, text = "Author")

# manual removal text boxes
txtRBT = Entry(fRB, width = 15)
txtRBA = Entry(fRB, width = 15)

# frame to manulally remove a CD item
frmRemoveCD = LabelFrame(fRS, text = "Manually Remove CD Item", labelanchor = "n")
fRC = frmRemoveCD

# entry requirement labels to remove a CD
lblRCT = Label(fRC, text = "CD Title")
lblRCA = Label(fRC, text = "Artist")

# manual removel text boxes
txtRCT = Entry(fRC, width = 15)
txtRCA = Entry(fRC, width = 15)

# Remove Stock Button
btnRemoveStock = Button(fRS, text = "Remove Stock Items", width = 15, height = 2, command = removeStockFromDB)


# -------------- Pack Widgets ---------------

# pack all widgets into the main window

# main frame to hold everything
frmMain.grid(column = 0, row = 0)

# client name selection
lblClient.grid(column = 0, row = 0, sticky = E, padx = 5, pady = 10)
opmClient.grid(column = 1, row = 0, sticky = W, padx = 5, pady = 10)

# add stock section
fAS.grid(column = 0, row = 1, columnspan = 2, padx = 10, pady = 10)
# add a book manually
fAB.grid(column = 0, row = 0, columnspan = 3, padx = 5, pady = 10)
# labels for manual book entry
lblABT.grid(column = 0, row = 0, padx = 5, pady = 5)
lblABA.grid(column = 1, row = 0, padx = 5, pady = 5)
lblABD.grid(column = 2, row = 0, padx = 5, pady = 5)
lblABG.grid(column = 3, row = 0, padx = 5, pady = 5)
lblABN.grid(column = 4, row = 0, padx = 5, pady = 5)
lblABP.grid(column = 5, row = 0, padx = 5, pady = 5)
lblABW.grid(column = 6, row = 0, padx = 5, pady = 5)
# text entry for manual book entry
txtABT.grid(column = 0, row = 1, padx = 5, pady = 5)
txtABA.grid(column = 1, row = 1, padx = 5, pady = 5)
txtABD.grid(column = 2, row = 1, padx = 5, pady = 5)
txtABG.grid(column = 3, row = 1, padx = 5, pady = 5)
txtABN.grid(column = 4, row = 1, padx = 5, pady = 5)
txtABP.grid(column = 5, row = 1, padx = 5, pady = 5)
txtABW.grid(column = 6, row = 1, padx = 5, pady = 5)

# add a CD manually
fAC.grid(column = 0, row = 2, columnspan = 3, padx = 5, pady = 10)
# labels for manual CD entry
lblACT.grid(column = 0, row = 0, padx = 5, pady = 5)
lblACA.grid(column = 1, row = 0, padx = 5, pady = 5)
lblACD.grid(column = 2, row = 0, padx = 5, pady = 5)
lblACG.grid(column = 3, row = 0, padx = 5, pady = 5)
lblACN.grid(column = 4, row = 0, padx = 5, pady = 5)
lblACP.grid(column = 5, row = 0, padx = 5, pady = 5)
lblACW.grid(column = 6, row = 0, padx = 5, pady = 5)
# manual entry text boxes
txtACT.grid(column = 0, row = 1, padx = 5, pady = 5)
txtACA.grid(column = 1, row = 1, padx = 5, pady = 5)
txtACD.grid(column = 2, row = 1, padx = 5, pady = 5)
txtACG.grid(column = 3, row = 1, padx = 5, pady = 5)
txtACN.grid(column = 4, row = 1, padx = 5, pady = 5)
txtACP.grid(column = 5, row = 1, padx = 5, pady = 5)
txtACW.grid(column = 6, row = 1, padx = 5, pady = 5)

# Add Stock Button
btnAddStock.grid(column = 1, row = 3, padx = 5, pady = 10)

# remove stock section
fRS.grid(column = 0, row = 2,  columnspan = 2, padx = 10, pady = 10)
# remove a book manually
fRB.grid(column = 0, row = 0, padx = 5, pady = 10)
# labels for manual book removal
lblRBT.grid(column = 0, row = 0, padx = 5, pady = 5)
lblRBA.grid(column = 1, row = 0, padx = 5, pady = 5)
# text entry for manual book removal
txtRBT.grid(column = 0, row = 1, padx = 5, pady = 5)
txtRBA.grid(column = 1, row = 1, padx = 5, pady = 5)

# remove a CD manually
fRC.grid(column = 1, row = 0, padx = 5, pady = 10)
# labels for manual CD removal
lblRCT.grid(column = 0, row = 0, padx = 5, pady = 5)
lblRCA.grid(column = 1, row = 0, padx = 5, pady = 5)
# manual removal text boxes
txtRCT.grid(column = 0, row = 1, padx = 5, pady = 5)
txtRCA.grid(column = 1, row = 1, padx = 5, pady = 5)

# Remove Stock Button
btnRemoveStock.grid(column = 0, row = 1, columnspan = 2, padx = 5, pady = 10)

# start main window when program runs
mWin.mainloop()

