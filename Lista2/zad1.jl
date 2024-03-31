struct NaiveBayessClassifier

    histogramHam::Dict
    histogramSpam::Dict

    hamWordCount::Int64
    spamWordCount::Int64

    hamProb::Float64
    spamProb::Float64

end

@enum Category SPAM HAM

function createHistograms(spamHamPath::String)::NaiveBayessClassifier

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

        if message[1] == "ham"
            
            hamMessageCount += 1

            for word in message[2:length(message)]

                normWord = lowercase(word)

                if word == ""
                    continue
                end

                hamWordCount += 1

                if haskey(histogramHam, normWord)
                    histogramHam[normWord] += 1
                else
                    histogramHam[normWord] = 1
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

                if haskey(histogramSpam, normWord)
                    histogramSpam[normWord] += 1
                else
                    histogramSpam[normWord] = 1
                end

            end

        end
        
    end 

    for (key, val) in histogramHam

        histogramHam[key] = histogramHam[key] / messageCount

    end

    for (key, val) in histogramSpam

        histogramSpam[key] = histogramSpam[key] / messageCount

    end

    hamMessageProb::Float64 = hamMessageCount / messageCount
    spamMessageProb::Float64 = spamMessageCount / messageCount

    return NaiveBayessClassifier(histogramHam, histogramSpam, hamWordCount, spamWordCount, hamMessageProb, spamMessageProb)

end

function classify(classifier::NaiveBayessClassifier, message::Vector{SubString{String}})::Category

    pCs::Float64 = classifier.spamProb
    pCh::Float64 = classifier.hamProb

    pXCs::Float64 = classifier.spamProb
    pXCh::Float64 = classifier.hamProb

    for word in message

        if word != "" && haskey(classifier.histogramHam, word)

            pXCh = pXCh * classifier.histogramHam[word] 

        else

            pXCh = pXCh * (1 / classifier.hamWordCount)

        end

    end

    for word in message

        if word != "" && haskey(classifier.histogramSpam, word)

            pXCs = pXCs * classifier.histogramSpam[word] 

        else

            pXCs = pXCs * (1 / classifier.spamWordCount)

        end

    end

    println(pXCh)
    println(pXCs)

    result = (pCh*pXCh)/((pCs*pXCs)+(pCh*pXCh))

    if result > 0.5
        return HAM
    else
        return SPAM
    end

end

function classifierTest(classifier::NaiveBayessClassifier, testFilePath::String)

    f = open(testFilePath, "r")

    fileLines = readlines(f)

    excludedChars::Array{Char} = ['-','/','\\', '#', '^', '&', '*', ';', ':', '\"', '\'', '<', '>', '-', ' ', '.', ',', '\t', '\n', '\r', '?', '%', '!', '+']

    messageCount::Int64 = 0

    spamMessageCount::Int64 = 0
    hamMessageCount::Int64 = 0

    spamClassifiedCorrectlyCount::Int64 = 0
    hamClassifiedCorrectlyCount::Int64 = 0

    for line in fileLines

        messageCount += 1

        message::Array = split(line, excludedChars)

        if message[1] == "ham"
            
            hamMessageCount += 1

            result = classify(classifier, message[2:length(message)])

            if result == HAM
                hamClassifiedCorrectlyCount += 1
            end

        elseif message[1] == "spam"

            spamMessageCount += 1

            result = classify(classifier, message[2:length(message)])

            if result == SPAM
                spamClassifiedCorrectlyCount += 1
            end


        end
        
    end 

    println("HAM MESSAGES COUNT: ", hamMessageCount)
    println("HAM CLASSIFIED: ", hamClassifiedCorrectlyCount)
    println("SPAM MESSAGES COUNT: ", spamMessageCount)
    println("SPAM CLASSIFIED:: ", spamClassifiedCorrectlyCount)

end

function main()

    naiveBC::NaiveBayessClassifier = createHistograms("/home/rychu/UMSI/Lista2/SMSSpamCollection.txt")

    println(naiveBC)
    excludedChars::Array{Char} = ['-','/','\\', '#', '^', '&', '*', ';', ':', '\"', '\'', '<', '>', '-', ' ', '.', ',', '\t', '\n', '\r', '?', '%', '!', '+']
   classifierTest(naiveBC, "/home/rychu/UMSI/Lista2/SMSSpamTest.txt")

end

main()