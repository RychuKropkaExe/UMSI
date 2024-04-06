struct BayessClassifier

    histogramsHam::Array{Dict}
    histogramsSpam::Array{Dict}

    hamWordCounts::Array{Int64}
    spamWordCounts::Array{Int64}

    hamProb::Float64
    spamProb::Float64
    
    maxEngramSize::Int64

end

@enum Category SPAM HAM

function createHistograms(spamHamPath::String, maxEngramSize::Int64)::BayessClassifier

    f = open(spamHamPath, "r")

    fileLines = readlines(f)

    histogramsHam::Array{Dict} = [Dict() for _ in 1:maxEngramSize]
    histogramsSpam::Array{Dict} = [Dict() for _ in 1:maxEngramSize]


    hamWordCounts::Array{Int64} = [0 for i in 1:maxEngramSize]
    spamWordCounts::Array{Int64} = [0 for i in 1:maxEngramSize]

    excludedChars::Array{Char} = ['-','/','\\', '#', '^', '&', '*', ';', ':', '\"', '\'', '<', '>', '-', ' ', '.', ',', '\t', '\n', '\r', '?', '%', '!', '+']

    messageCount::Int64 = 0

    spamMessageCount::Int64 = 0
    hamMessageCount::Int64 = 0

    for line in fileLines

        messageCount += 1

        message::Array = split(line, excludedChars)

        message = [i for i in message if i != ""]

        #println(message)

        if message[1] == "ham"
            
            hamMessageCount += 1

            for i in 1:maxEngramSize

                for j in 2:length(message)-(i-1)

                    normWord = lowercase(message[j])

                    for k in 2:i
                        normWord = normWord*lowercase(message[j+k-1])
                    end
    
                    if normWord == ""
                        println("WORD EMPTY: ", normWord)
                        exit(0)
                    end
    
                    hamWordCounts[i] += 1
                    
                    if haskey(histogramsHam[i], normWord)
                        histogramsHam[i][normWord] += 1
                    else
                        histogramsHam[i][normWord] = 1
                    end

    
                end

            end


        elseif message[1] == "spam"

            spamMessageCount += 1

            for i in 1:maxEngramSize

                for j in 2:length(message)-(i-1)

                    normWord = lowercase(message[j])

                    for k in 2:i
                        normWord = normWord*lowercase(message[j+k-1])
                    end

                    if normWord == ""
                        println("WORD EMPTY: ", normWord)
                        exit(0)
                    end
    
                    spamWordCounts[i] += 1
                    
                    if haskey(histogramsSpam[i], normWord)
                        histogramsSpam[i][normWord] += 1
                    else
                        histogramsSpam[i][normWord] = 1
                    end

                end

            end
        end
    end 

    #println(spamWordCounts)

    for i in 1:maxEngramSize

        for (key, val) in histogramsHam[i]

            histogramsHam[i][key] = histogramsHam[i][key] / hamWordCounts[i]
    
        end
    
        for (key, val) in histogramsSpam[i]
    
            histogramsSpam[i][key] = histogramsSpam[i][key] / spamWordCounts[i]
    
        end

    end

    hamMessageProb::Float64 = hamMessageCount / messageCount
    spamMessageProb::Float64 = spamMessageCount / messageCount

    return BayessClassifier(histogramsHam, histogramsSpam, hamWordCounts, spamWordCounts, hamMessageProb, spamMessageProb, maxEngramSize)

end

function classify(classifier::BayessClassifier, message::Vector{SubString{String}})::Array{Category}

    pCs::Float64 = classifier.spamProb
    pCh::Float64 = classifier.hamProb

    pXCsProbs::Array{Float64} = [log(classifier.spamProb) for _ in 1:classifier.maxEngramSize]
    pXChProbs::Array{Float64} = [log(classifier.hamProb) for _ in 1:classifier.maxEngramSize]

    histograms::Array{Dict} = [Dict() for _ in 1:classifier.maxEngramSize]

    normMessage = [lowercase(i) for i in message if i != ""]

    for i in 1:classifier.maxEngramSize

        for j in 1:length(normMessage)-(i-1)

            word = normMessage[j]

            for k in 2:i

                word = word*normMessage[j+k-1]

            end

            if haskey(histograms[i], word)
    
                histograms[i][word] += 1
    
            elseif word != ""
    
                histograms[i][word] = 1
    
            end
    
        end

    end

    for i in 1:classifier.maxEngramSize

        for (key, val) in histograms[i]

            #println(val)

            if haskey(classifier.histogramsHam[i], key)

                pXChProbs[i] = pXChProbs[i] + log(classifier.histogramsHam[i][key])*val

            else

                pXChProbs[i] = pXChProbs[i] + log((1 / classifier.hamWordCounts[i]))

            end

            if haskey(classifier.histogramsSpam[i], key)

                pXCsProbs[i] = pXCsProbs[i] + log(classifier.histogramsSpam[i][key])*val

            else

                pXCsProbs[i] = pXCsProbs[i] + log((1 / classifier.spamWordCounts[i]))

            end

        end

    end

    #println(pXChProbs)
    #println(pXCsProbs)

    results::Array{Category} = [HAM for i in 1:classifier.maxEngramSize]

    for i in 1:classifier.maxEngramSize

        if pXChProbs[i] > pXCsProbs[i]
            results[i] = HAM
        else
            results[i] = SPAM
        end

    end

    return results

end

function classifierTest(classifier::BayessClassifier, testFilePath::String)

    f = open(testFilePath, "r")

    fileLines = readlines(f)

    excludedChars::Array{Char} = ['-','/','\\', '#', '^', '&', '*', ';', ':', '\"', '\'', '<', '>', '-', ' ', '.', ',', '\t', '\n', '\r', '?', '%', '!', '+']

    messageCount::Int64 = 0

    spamMessageCount::Int64 = 0
    hamMessageCount::Int64 = 0

    spamClassifiedCorrectlyCounts::Array{Int64} = [0 for _ in 1:classifier.maxEngramSize]
    hamClassifiedCorrectlyCounts::Array{Int64} = [0 for _ in 1:classifier.maxEngramSize]

    hamClassifiedCounts::Array{Int64} = [0 for _ in 1:classifier.maxEngramSize]
    spamClassifiedCounts::Array{Int64} = [0 for _ in 1:classifier.maxEngramSize]



    for line in fileLines

        messageCount += 1

        message::Array = split(line, excludedChars)

        if message[1] == "ham"
            
            hamMessageCount += 1

            result = classify(classifier, message[2:length(message)])
                
            #println(result)

            for i in 1:classifier.maxEngramSize
                if result[i] == HAM
                    hamClassifiedCorrectlyCounts[i] += 1
                    hamClassifiedCounts[i] += 1
                else
                    spamClassifiedCounts[i] += 1
                end
            end

        elseif message[1] == "spam"

            spamMessageCount += 1

            result = classify(classifier, message[2:length(message)])

            #println(result)


            for i in 1:classifier.maxEngramSize
                if result[i] == SPAM
                    spamClassifiedCorrectlyCounts[i] += 1
                    spamClassifiedCounts[i] += 1
                else
                    hamClassifiedCounts[i] += 1
                end
            end


        end
        
    end 
    for i in 1:classifier.maxEngramSize
        println("-------------------------------------------------------")
        println("HAM MESSAGES COUNT: ", hamMessageCount)
        println("HAM CLASSIFIED: ", hamClassifiedCounts[i])
        println("HAM CLASSIFIED CORRECTLY: ", hamClassifiedCorrectlyCounts[i])
        println("SPAM MESSAGES COUNT: ", spamMessageCount)
        println("SPAM CLASSIFIED: ", spamClassifiedCounts[i])
        println("SPAM CLASSIFIED CORRECTLY: ", spamClassifiedCorrectlyCounts[i])

        println("ACCURACY HAM: ", hamClassifiedCorrectlyCounts[i]/hamMessageCount)
        println("ACCURACY SPAM: ", spamClassifiedCorrectlyCounts[i]/spamMessageCount)

        TPTN = hamClassifiedCorrectlyCounts[i] + spamClassifiedCorrectlyCounts[i]
        FPFN = (hamMessageCount - hamClassifiedCorrectlyCounts[i]) + (spamMessageCount - spamClassifiedCorrectlyCounts[i])

        println("OVERALL ACCURACY: ", TPTN/(TPTN+FPFN))
        println("OVERALL ACCURACY: ", TPTN/(messageCount))
        println("-------------------------------------------------------")
    end

end

function main()

    naiveBC::BayessClassifier = createHistograms("/home/rychu/UMSI/Lista2/SMSSpamCollection.txt", 3)

    #println(naiveBC.histogramsHam[2])
    excludedChars::Array{Char} = ['-','/','\\', '#', '^', '&', '*', ';', ':', '\"', '\'', '<', '>', '-', ' ', '.', ',', '\t', '\n', '\r', '?', '%', '!', '+']
    classifierTest(naiveBC, "/home/rychu/UMSI/Lista2/SMSSpamTest.txt")

end

main()