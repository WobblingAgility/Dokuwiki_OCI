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
	lighttpd\
	php-cli\
	lighttpd-fastcgi\
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

# configure lighttpd and fast-cgi
sed -i s/apache/lighttpd/g $scratchmnt/etc/php-fpm.d/www.conf
sed -i s/"#include \"conf.d\/fastcgi.conf\""/"include \"conf.d\/fastcgi.conf\""/ $scratchmnt/etc/lighttpd/modules.conf
echo 'include "/etc/lighttpd/vhosts.d/*.conf"' >> $scratchmnt/etc/lighttpd/lighttpd.conf
echo 'cgi.fix_pathinfo=1' >> $scratchmnt/etc/php.ini
mkdir $scratchmnt/var/run/lighttpd
buildah run $newcontainer chown -R lighttpd:lighttpd /var/run/lighttpd
buildah add $newcontainer lighttpd-dokuwiki.conf /etc/lighttpd/vhosts.d/dokuwiki.conf

# install/configure dokuwiki
wget -p -O $scratchmnt/dokuwiki.tgz "https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz"
mkdir $scratchmnt/dokuwiki
tar -zxf $scratchmnt/dokuwiki.tgz -C $scratchmnt/dokuwiki --strip-components 1
buildah run $newcontainer chown -R lighttpd:lighttpd /dokuwiki

# configure volume mounts
buildah config --volume ["/dokuwiki/data/","/dokuwiki/lib/plugins/","/dokuwiki/conf/","/dokuwiki/lib/tpl/","/var/log/"]

# configure container
buildah config --label name=$name $newcontainer
buildah config --cmd "/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf" $newcontainer
buildah config --port 80 --port 443 $newcontainer

# commit the image
buildah unmount $newcontainer
buildah commit $newcontainer dbuckley/$name
