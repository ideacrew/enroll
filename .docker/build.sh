if nc -z localhost 15672 &> /dev/null; then
    echo "RabbitMQ is running."
else
    echo "RabbitMQ is not running. Please start this service to continue."
    exit 1
fi

if nc -z localhost 27017 &> /dev/null; then
    echo "MongoDB is running."
else
    echo "MongDB is not running. Please start this service to continue."
    exit 1
fi

# Get reference to sha for image tag
SHORT_SHA=$(git rev-parse HEAD | head -c7)

BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Put HEAD commit into docker image for reference later
git show --quiet HEAD > release.txt

REPO=public.ecr.aws/ideacrew/enroll
TAG=${BRANCH_NAME}-${SHORT_SHA}
CLIENT=me

echo "Building image ${REPO}:${TAG}-${CLIENT}"

docker build --build-arg CLIENT=${CLIENT} -f .docker/production/Dockerfile -t ${REPO}:${TAG}-${CLIENT} --network=host .

echo "Image built. Push to ECR with docker push ${REPO}:${TAG}-${CLIENT}"
