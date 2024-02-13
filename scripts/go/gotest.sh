go vet ./...

package_names=$(find . -name "*_test.go" -type f | xargs -I {} dirname {} | sort | uniq)

package=$(printf "$package_names" | fzf --height 40% --layout reverse --prompt "Select a package to test: ")

go test -v $package -cover
