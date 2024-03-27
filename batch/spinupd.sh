if [ "$1" == "--update" ]; then
    echo "updating stack.."
    aws cloudformation update-stack --stack-name Logan-AnalysisDisques --template-body file://templated.yaml --capabilities CAPABILITY_NAMED_IAM
else
    aws cloudformation create-stack --stack-name Logan-AnalysisDisques --template-body file://templated.yaml --capabilities CAPABILITY_NAMED_IAM
fi
