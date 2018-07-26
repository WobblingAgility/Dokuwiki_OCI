# title: dokuwiki OCI buildah script
# author: Derek Buckley
# created: 2018-07-26

newcontainer=$(buildah from scratch)
name=dokuwiki
scratchmnt=$(buildah mount $newcontainer)

#install the needed packages
dnf install\
       	bash\
	coreutils\
	tar\
	wget\
	nginx\
	php-fpm\
       	php-ldap\
	php-xml\
	php-gd\
	php-mbstring\
	curl\
	curl-devel\
	--installroot=$scratchmnt\
       	--releasever=$(rpm -E %fedora)\
	--setopt=install_weak_deps=false\
	--setopt=tsflags=nodocs\
	--setopt=override_install_langs=en_US.utf8 -y
dnf clean all -y --installroot $scratchmnt --releasever 7
rm -rf $scratchmnt/var/cache/yum

# install/configure dokuwiki
wget -p -O $scratchmnt/dokuwiki.tgz "https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz"
mkdir $scratchmnt/dokuwiki
tar -zxf $scratchmnt/dokuwiki.tgz -C $scratchmnt/dokuwiki --strip-components 1
buildah run $newcontainer chown -R nginx:nginx /dokuwiki

# configure container
buildah config --label name=$name $newcontainer

# commit the image
buildah unmount $newcontainer
buildah commit $newcontainer dbuckley/$name
