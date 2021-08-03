cd "./d source"
time dmd -O app.d types.d eval.d function.d reader.d buildins.d && mv ./app ../app
cd ..
#time dmd -debug app.d types.d eval.d function.d reader.d buildins.d
