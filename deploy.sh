hexo generate
msg=$(git log --pretty=format:"%s" HEAD -1)
cp -R public/* deploy/linsite.github.io
cd deploy/linsite.github.io
git add .
git commit -m "$msg"
git push origin main
