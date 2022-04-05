hexo generate
cp -R public/* .deploy/linsite.github.io
cd .deploy/linsite.github.io
git add .
git commit -m “update”
git push origin master
