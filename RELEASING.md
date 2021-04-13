1. Bump `VERSION` file
2. Rename `spec/dovetail-$VERSION.spec`
    - Bump Version
    - Adjust source URL
    - Add changelog entry
3. Ensure `spec/dovetail.rpkg.spec` reflects packaging changes
4. Test spec with `tb rpkg-install`
5. Commit with `Update version to $VERSION`
6. Tag release
7. Push commits and tag
