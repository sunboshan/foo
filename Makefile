APP = foo
ERTS = 9.3
VSN = 0.1.0
REL = /tmp/prod

compile:
	erlc -o ebin src/*.erl
	cp src/${APP}.app.src ebin/${APP}.app

release: compile
	erl -pa ebin -noshell \
		-eval 'systools:make_script("rel/${VSN}/${APP}")' \
		-eval 'systools:make_tar("rel/${VSN}/${APP}",[{erts,"/usr/local/Cellar/erlang/20.3.2/lib/erlang"}])' \
		-s init stop

deploy: release
	mkdir -p ${REL}/bin ${REL}/log/pipes
	tar xf rel/${VSN}/${APP}.tar.gz -C ${REL}
	cp ${REL}/erts-${ERTS}/bin/run_erl ${REL}/bin/
	cp ${REL}/erts-${ERTS}/bin/to_erl ${REL}/bin/
	cp ${REL}/erts-${ERTS}/bin/start.src ${REL}/bin/start
	cp ${REL}/erts-${ERTS}/bin/start_erl.src ${REL}/bin/start_erl
	sed -ie 's#/tmp/#$$ROOTDIR/log/pipes/#' ${REL}/bin/start # replace /tmp/ to $ROOTDIR/log/pipes/
	sed -ie 's#%FINAL_ROOTDIR%#${REL}#' ${REL}/bin/start     # replace %FINAL_ROOTDIR% to /tmp/prod
	echo "${ERTS} ${VSN}" > ${REL}/releases/start_erl.data
