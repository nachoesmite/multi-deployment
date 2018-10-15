
#if [ -d "./tmp" ] 
#then
#  cd tmp
#  git pull
#else
#  git clone git@github.com:nachoesmite/multi-deployment-sample.git tmp
  cd tmp
#fi

branchesArray=()
for branch in $(git for-each-ref --format='%(refname)' refs/remotes); do
    # git log --oneline "$branch" ^origin/master
    if [[ !($branch =~ refs/remotes/origin/(HEAD|master)$) ]]
    then
      branchesArray+=($(echo ${branch} | cut -d'/' -f 4))
    fi
done
[ -e ../branches.json ] && rm ../branches.json
touch ../branches.json
echo "[" >> ../branches.json

index=1
for branch in "${branchesArray[@]}"
do
  git checkout $branch
  version=$(git rev-parse HEAD)
  commit_timestamp=$(git log -1 --pretty=format:%ct)
  echo { \"branch\": \"$branch\", \"commit\": \"$version\", \"commit_timestamp\": \"$commit_timestamp\" } >> ../branches.json
  [ $index -ne ${#branchesArray[@]} ] &&  echo , >> ../branches.json
  if [[ "$(docker images -q deploy-$branch:$version 2> /dev/null)" == "" ]]; then
    docker build -t deploy-$branch:$version .
  fi
  ((index++))
done

echo "]" >> ../branches.json;

git checkout master