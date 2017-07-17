#!/usr/bin/make -f
#export DH_VERBOSE = 1

export M2_HOME=/usr/share/maven
export M2=${M2_HOME}/bin

export LOOM_TM_PATH=/usr/share/loom-tm
ESC_LOOM_TM_PATH=$(shell echo $(LOOM_TM_PATH) | sed -e '1,$$s/\//\\\//g')

export LOOM_TM_REPO_PATH=/usr/share/loom-tm-repo
ESC_LOOM_TM_REPO_PATH=$(shell echo $(LOOM_TM_REPO_PATH) | sed -e '1,$$s/\//\\\//g')

MVN=mvn
MVN_ARGS=-Dmaven.repo.local=debian/maven-repo -DproxySet=true -DproxyHost=<**set this**> -DproxyPort=8080 -DskipTests=true
CWD=$(shell pwd)

loom: settings_xml
	$(MVN) -s $(HOME)/.m2_loom/settings.xml clean install

settings_xml:
	if [ ! -d ${HOME}/.m2_loom ]; then \
		 mkdir ${HOME}/.m2_loom ;\
	fi
	cp settings.xml ${HOME}/.m2_loom/
	sed -i -e '/<\/proxies>/a  <localRepository>.\/loom-tm-repo\/repository\/<\/localRepository>' ${HOME}/.m2_loom/settings.xml ;\
	if [ -d ${LOOM_TM_REPO_PATH}/repository ] ; then \
		if [ ! -d loom-tm-repo/repository ] ; then \
			mkdir -p loom-tm-repo/repository ;\
		fi ;\
		cp -R --preserv=links ${LOOM_TM_REPO_PATH}/* loom-tm-repo ;\
	fi

deepclean:
	rm -rf ./loom-tm-repo
	if [ -d .git ] ; then \
		git checkout debian/control; \
	fi

clean: distclean

distclean: settings_xml
	$(MVN) -s $(HOME)/.m2_loom/settings.xml clean
	rm -rf ./debian/loom-tm
	rm -rf target
	grep "Build-Depends:.*loom-tm" debian/control || \
		( cp debian/control debian/.control; \
		sed -i -e 's/Build-Depends:/Build-Depends: loom-tm-repo, /'  debian/control )

install:
	# Server
	mkdir -p ./debian/loom-tm/$(LOOM_TM_PATH)/target
	mkdir -p ./debian/loom-tm/$(LOOM_TM_PATH)/logs
	install -m 755 target/jetty-runner.jar ./debian/loom-tm/$(LOOM_TM_PATH)/target
	install -m 755 target/loom-server.war ./debian/loom-tm/$(LOOM_TM_PATH)/target
	install -m 755 target/weaver.war ./debian/loom-tm/$(LOOM_TM_PATH)/target
	install -m 755 target/tm-ed.war ./debian/loom-tm/$(LOOM_TM_PATH)/target
	install -m 755 deployment.properties ./debian/loom-tm/$(LOOM_TM_PATH)/deployment-deb.properties
	install -m 755 jetty.xml ./debian/loom-tm/$(LOOM_TM_PATH)
	install -m 755 override-loom-web.xml ./debian/loom-tm/$(LOOM_TM_PATH)
	install -m 755 loom-context.xml ./debian/loom-tm/$(LOOM_TM_PATH)
	install -m 755 md-context.xml ./debian/loom-tm/$(LOOM_TM_PATH)
	install -m 755 ed-context.xml ./debian/loom-tm/$(LOOM_TM_PATH)
	install -m 644 log4j-deb.properties ./debian/loom-tm/$(LOOM_TM_PATH)
	install -m 644 keystore ./debian/loom-tm/$(LOOM_TM_PATH)
	install -m 644 truststore ./debian/loom-tm/$(LOOM_TM_PATH)
	sed -i -e 's/adapter.configs=/adapter.configs=$(ESC_LOOM_TM_PATH)\//' ./debian/loom-tm/$(LOOM_TM_PATH)/deployment-deb.properties
	sed -i -e 's/adapterDir=/adapterDir=$(ESC_LOOM_TM_PATH)\//' ./debian/loom-tm/$(LOOM_TM_PATH)/deployment-deb.properties
	sed -i -e 's/log4j.appender.file.RollingPolicy=/log4j.appender.file.File=$(ESC_LOOM_TM_PATH)\/logs\/loom.log\nlog4j.rootLogger=info\nlog4j.appender.file.RollingPolicy=/' ./debian/loom-tm/$(LOOM_TM_PATH)/log4j-deb.properties 
	install -m 755 run_loom.sh ./debian/loom-tm/$(LOOM_TM_PATH)
	mkdir -p ./debian/loom-tm/etc/systemd/system
	install -m 644 loom-tm.service ./debian/loom-tm/etc/systemd/system
	mkdir -p ./debian/loom-tm/$(LOOM_TM_PATH)/adapters
	install -m 755 adapters/*.jar ./debian/loom-tm/$(LOOM_TM_PATH)/adapters
	install -m 755 adapters/myadapter.properties ./debian/loom-tm/$(LOOM_TM_PATH)/adapters
	if [ -f debian/.control ] ; then \
		 mv debian/.control debian/control ;\
	fi
	rm -f ${HOME}/.m2_loom/settings.xml

	mkdir -p ./debian/loom-tm-repo/$(LOOM_TM_REPO_PATH)/repository
	cp -R --preserve=links loom-tm-repo/* ./debian/loom-tm-repo/$(LOOM_TM_REPO_PATH)/
	if [ -d .git ] ; then \
		git checkout debian/control; \
	fi


