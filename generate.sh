#!/bin/bash

rm -rf download
git clone https://github.com/shadcn/next-template download

pushd ./download
npx shadcn-ui add --overwrite --yes accordion alert alert-dialog aspect-ratio avatar badge button calendar card checkbox collapsible command context-menu dialog dropdown-menu form hover-card input label menubar navigation-menu popover progress radio-group scroll-area select separator sheet skeleton slider switch table tabs textarea toast toggle tooltip
popd

version=$(cat package.json | jq ".version")
templatePackageJson=$(cat download/package.json)

# --- Main Package ---

mainPackageDir=packages/shadcn-ui
mainPackageSrcDir=$mainPackageDir/src
mainPackageIndexPath=$mainPackageSrcDir/index.ts
mainPackagePackageJsonPath=$mainPackageDir/package.json

mkdir -p $mainPackageDir
mkdir -p $mainPackageSrcDir

rm -rf $mainPackageIndexPath

touch $mainPackageIndexPath
touch $mainPackagePackageJsonPath

mainPackagePackageJsonContent="{
  \"name\": \"@teovilla/shadcn-ui-react\",
  \"version\": $version,
  \"main\": \"src/index.ts\",
  \"dependencies\": {
    \"@teovilla/shadcn-ui-react-lib\": $version
  },
  \"scripts\": {
    \"publish-package\": \"npm publish --access public\"
  },
  \"publishConfig\": {
    \"registry\": \"https://registry.npmjs.org/\",
    \"access\": \"public\"
  },
  \"repository\": \"https://github.com/teovillanueva/shadcn-ui-react\",
  \"author\": \"Teodoro Villanueva <teodoro2102@gmail.com> (https://github.com/teovillanueva)\",
  \"bugs\": {
    \"url\": \"https://github.com/teovillanueva/shadcn-ui-react/issues\"
  },
  \"homepage\": \"https://github.com/teovillanueva/shadcn-ui-react#readme\"
}"

# --- LIB Package ---

libDir=packages/lib
libSrcDir=$libDir/src
libIndexPath=$libSrcDir/index.ts
libPackageJsonPath=$libDir/package.json
libPackageJsonContent="{
  \"name\": \"@teovilla/shadcn-ui-react-lib\",
  \"version\": $version,
  \"main\": \"src/index.ts\",
  \"scripts\": {
    \"publish-package\": \"npm publish --access public\"
  },
  \"publishConfig\": {
    \"registry\": \"https://registry.npmjs.org/\",
    \"access\": \"public\"
  },
  \"repository\": \"https://github.com/teovillanueva/shadcn-ui-react\",
  \"author\": \"Teodoro Villanueva <teodoro2102@gmail.com> (https://github.com/teovillanueva)\",
  \"bugs\": {
    \"url\": \"https://github.com/teovillanueva/shadcn-ui-react/issues\"
  },
  \"homepage\": \"https://github.com/teovillanueva/shadcn-ui-react#readme\"
}"

mkdir -p $libDir
mkdir -p $libSrcDir

touch $libPackageJsonPath

rm -rf $libIndexPath
touch $libIndexPath

for file in ./download/lib/*; do
  filename=$(basename -- "$file")
  component="${filename%.*}"

  imports=$(awk -F '\t' '/import/' "$file")

  while IFS= read -r line; do
    import="${line##* }"
    packageDepVersion=$(echo "$templatePackageJson" | jq ".dependencies[$import]")
    libPackageJsonContent=$(echo "$libPackageJsonContent" | jq ".dependencies[$import] = $packageDepVersion")

  done <<<"$imports"

  cp "$file" packages/lib/src

  echo "export * from \"./$component\"" >>$libIndexPath

done

echo "$libPackageJsonContent" >$libPackageJsonPath

# --- Component Packages ---

for file in ./download/components/ui/*; do
  filename=$(basename -- "$file")
  component="${filename%.*}"

  packageDir="packages/$component"
  packageSrcDir="$packageDir/src"

  packageIndexPath="$packageSrcDir/index.tsx"
  packageJsonPath="$packageDir/package.json"
  packageName=@teovilla/shadcn-ui-react-$component

  mkdir -p "packages/$component"
  touch "$packageJsonPath"

  packageJsonContent="{
  \"name\": \"$packageName\",
  \"version\": $version,
  \"main\": \"src/index.tsx\",
  \"scripts\": {
    \"publish-package\": \"npm publish --access public\"
  },
  \"dependencies\": {
    \"@teovilla/shadcn-ui-react-lib\": $version
  },
  \"publishConfig\": {
    \"registry\": \"https://registry.npmjs.org/\",
    \"access\": \"public\"
  },
  \"repository\": \"https://github.com/teovillanueva/shadcn-ui-react\",
  \"author\": \"Teodoro Villanueva <teodoro2102@gmail.com> (https://github.com/teovillanueva)\",
  \"bugs\": {
    \"url\": \"https://github.com/teovillanueva/shadcn-ui-react/issues\"
  },
  \"homepage\": \"https://github.com/teovillanueva/shadcn-ui-react#readme\"
}"

  mainPackagePackageJsonContent=$(echo "$mainPackagePackageJsonContent" | jq ".dependencies[\"$packageName\"] = $version")

  mkdir -p "$packageSrcDir"

  cp "$file" "$packageIndexPath"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/\@\/lib\/utils/\@teovilla\/shadcn-ui-react-lib/' "$packageIndexPath"
  else
    sed -i 's/\@\/lib\/utils/\@teovilla\/shadcn-ui-react-lib/' "$packageIndexPath"
  fi

  imports=$(awk -F '\t' '/import/' "$packageIndexPath")

  while IFS= read -r line; do
    import="${line##* }"
    if test "$import" != "\"@teovilla/shadcn-ui-react-lib\""; then
      packageDepVersion=$(echo "$templatePackageJson" | jq ".dependencies[$import]")
      packageJsonContent=$(echo "$packageJsonContent" | jq ".dependencies[$import] = $packageDepVersion")
    fi
  done <<<"$imports"

  echo "$packageJsonContent" >"$packageJsonPath"
  echo "export * from \"$packageName\"" >>$mainPackageIndexPath

done

echo "$mainPackagePackageJsonContent" >"$mainPackagePackageJsonPath"
