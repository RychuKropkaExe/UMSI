struct BayessClassifier

    histogramHam::Dict
    histogramSpam::Dict

    hamMessageCount::Int64
    spamMessageCount::Int64

    hamProb::Float64
    spamProb::Float64

end

@enum Category SPAM HAM

function createHistograms(spamHamPath::String)::BayessClassifier

    f = open(spamHamPath, "r")

    fileLines = readlines(f)

    histogramHam::Dict = Dict()
    histogramSpam::Dict = Dict()
    hamWordCount::Int64 = 0
    spamWordCount::Int64 = 0

    excludedChars::Array{Char} = ['-','/','\\', '#', '^', '&', '*', ';', ':', '\"', '\'', '<', '>', '-', ' ', '.', ',', '\t', '\n', '\r', '?', '%', '!', '+']

    messageCount::Int64 = 0
    spamMessageCount::Int64 = 0
    hamMessageCount::Int64 = 0

    for line in fileLines

        messageCount += 1

        message::Array = split(line, excludedChars)

        alreadyUsed::Dict = Dict()

        if message[1] == "ham"
            
            hamMessageCount += 1

            for word in message[2:length(message)]

                normWord = lowercase(word)

                if word == ""
                    continue
                end

                hamWordCount += 1

                if haskey(histogramHam, normWord) && !haskey(alreadyUsed, normWord)
                    histogramHam[normWord] += 1
                    alreadyUsed[normWord] = 0
                elseif !haskey(histogramHam, normWord)
                    histogramHam[normWord] = 1
                    alreadyUsed[normWord] = 0
                    #println("CLASSIFIED???")
                end

            end

        elseif message[1] == "spam"

            spamMessageCount += 1

            for word in message[2:length(message)]

                if word == ""
                    continue
                end

                spamWordCount+= 1

                normWord = lowercase(word)

                if haskey(histogramSpam, normWord) && !haskey(alreadyUsed, normWord)
                    histogramSpam[normWord] += 1
                    alreadyUsed[normWord] = 0
                elseif !haskey(histogramSpam, normWord)
                    histogramSpam[normWord] = 1
                    alreadyUsed[normWord] = 0
                end

            end

        end
        
    end 

    for (key, val) in histogramHam

        histogramHam[key] = histogramHam[key] / hamMessageCount

    end

    for (key, val) in histogramSpam

        histogramSpam[key] = histogramSpam[key] / spamMessageCount

    end

    hamMessageProb::Float64 = hamMessageCount / messageCount
    spamMessageProb::Float64 = spamMessageCount / messageCount

    return BayessClassifier(histogramHam, histogramSpam, hamMessageCount, spamMessageCount, hamMessageProb, spamMessageProb)

end

function classify(classifier::BayessClassifier, message::Vector{SubString{String}})::Category

    pCs::Float64 = classifier.spamProb
    pCh::Float64 = classifier.hamProb

    pXCs::Float64 = classifier.spamProb
    pXCh::Float64 = classifier.hamProb

    alreadyUsed::Dict = Dict()

    normMessage = [lowercase(i) for i in message if i != ""]

    for word in normMessage

        if haskey(classifier.histogramHam, word) && !haskey(alreadyUsed, word)

            pXCh = pXCh * classifier.histogramHam[word] 

        elseif !haskey(alreadyUsed, word)

            pXCh = pXCh * (1 / classifier.hamMessageCount)

        end

    end

    alreadyUsed = Dict()

    for word in normMessage

        if haskey(classifier.histogramSpam, word) && !haskey(alreadyUsed, word)

            pXCs = pXCs * classifier.histogramSpam[word] 

            #println("SIEMA ENIU")

        elseif !haskey(alreadyUsed, word)

            pXCs = pXCs * (1 / classifier.spamMessageCount)
            #println("PODAJ TLENU")

        end

    end

    #println(pXCh)
    #println(pXCs)

    result = (pCh*pXCh)/((pCs*pXCs)+(pCh*pXCh))

    if result > 0.5
        return HAM
    else
        return SPAM
    end

end

function classifierTest(classifier::BayessClassifier, testFilePath::String)

    f = open(testFilePath, "r")

    fileLines = readlines(f)

    excludedChars::Array{Char} = ['-','/','\\', '#', '^', '&', '*', ';', ':', '\"', '\'', '<', '>', '-', ' ', '.', ',', '\t', '\n', '\r', '?', '%', '!', '+']

    messageCount::Int64 = 0

    spamMessageCount::Int64 = 0
    hamMessageCount::Int64 = 0

    spamClassifiedCorrectlyCount::Int64 = 0
    hamClassifiedCorrectlyCount::Int64 = 0

    hamClassifiedCount::Int64 = 0
    spamClassifiedCount::Int64 = 0

    for line in fileLines

        messageCount += 1

        message::Array = split(line, excludedChars)

        if message[1] == "ham"
            
            hamMessageCount += 1

            result = classify(classifier, message[2:length(message)])

            if result == HAM
                hamClassifiedCorrectlyCount += 1
                hamClassifiedCount += 1
            else
                spamClassifiedCount += 1
            end

        elseif message[1] == "spam"

            spamMessageCount += 1

            result = classify(classifier, message[2:length(message)])

            if result == SPAM
                spamClassifiedCorrectlyCount += 1
                spamClassifiedCount += 1
            else
                hamClassifiedCount += 1
            end


        end
        
    end 

    println("HAM MESSAGES COUNT: ", hamMessageCount)
    println("HAM CLASSIFIED: ", hamClassifiedCount)
    println("HAM CLASSIFIED CORRECTLY: ", hamClassifiedCorrectlyCount)
    println("SPAM MESSAGES COUNT: ", spamMessageCount)
    println("SPAM CLASSIFIED: ", spamClassifiedCount)
    println("SPAM CLASSIFIED CORRECTLY: ", spamClassifiedCorrectlyCount)

    println("ACCURACY HAM: ", hamClassifiedCorrectlyCount/hamClassifiedCount)
    println("ACCURACY SPAM: ", spamClassifiedCorrectlyCount/spamClassifiedCount)

    TPTN = hamClassifiedCorrectlyCount + spamClassifiedCorrectlyCount
    FPFN = (hamMessageCount - hamClassifiedCorrectlyCount) + (spamMessageCount - spamClassifiedCorrectlyCount)

    println("OVERALL ACCURACY: ", TPTN/(TPTN+FPFN))
    println("OVERALL ACCURACY: ", TPTN/(messageCount))

end

function main()

    naiveBC::BayessClassifier = createHistograms("/home/rychu/UMSI/Lista2/SMSSpamCollection.txt")

    #println(naiveBC)
    excludedChars::Array{Char} = ['-','/','\\', '#', '^', '&', '*', ';', ':', '\"', '\'', '<', '>', '-', ' ', '.', ',', '\t', '\n', '\r', '?', '%', '!', '+']
   classifierTest(naiveBC, "/home/rychu/UMSI/Lista2/SMSSpamTest.txt")

end

main()