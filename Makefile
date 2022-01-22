# $OpenBSD$

# Need a rebol3 binary to bootstrap the build
ONLY_FOR_ARCHS =	amd64 i386

COMMENT =	oldes branch of rebol3 interpreter

DISTNAME =	Rebol3-3.7.2pl7
PKGNAME =	rebol3-3.7.2pl7
V =		710e6693e995150d093b0ce6de252bdf4dbe5c97

SISKIN_V =	0.7.2

BV-amd64 =	3.7.2-20220106
BV-i386 =	3.7.2-20220111
BV =		${BV-${MACHINE_ARCH}}

CATEGORIES =	lang

HOMEPAGE =	https://github.com/Oldes/Rebol3

#MAINTAINER =		???

# Apache-2.0
PERMIT_PACKAGE =	Yes

# If pledge is used, annotate with `uses pledge()' in a comment

WANTLIB +=	c m iconv

MASTER_SITES =	https://github.com/Oldes/Rebol3/archive/
MASTER_SITES0 =	https://github.com/Siskin-framework/Builder/archive/
MASTER_SITES1 =	http://kapouay.odns.fr/pub/rebol3/

DISTFILES += 	rebol3-oldes-${V}${EXTRACT_SUFX}{${V}${EXTRACT_SUFX}} \
		siskin-${SISKIN_V}${EXTRACT_SUFX}{${SISKIN_V}${EXTRACT_SUFX}}:0

.include <bsd.port.arch.mk>
.for m in ${ONLY_FOR_ARCHS}
BOOTSTRAP_DIR-$m =	rebol3-bootstrap-${BV-$m}-$m
BOOTSTRAP-$m =		${BOOTSTRAP_DIR-$m}${EXTRACT_SUFX}:1
SUPDISTFILES +=		${BOOTSTRAP_DIR-$m}${EXTRACT_SUFX}:1
.endfor

FLAVOR ?=
PSEUDO_FLAVORS =	native_bootstrap

.if ${FLAVOR} == native_bootstrap
BUILD_DEPENDS +=	lang/rebol3
.else
DISTFILES +=		${BOOTSTRAP-${MACHINE_ARCH}}
.endif

# which target to build
ALL_TARGET-amd64 =	openbsd-x64
ALL_TARGET-i386 =	openbsd-x86
ALL_TARGET =		${ALL_TARGET-${MACHINE_ARCH}}

LIB_DEPENDS =		converters/libiconv

#SEPARATE_BUILD =	Yes

CONFIGURE_STYLE =	none

# DEBUG_PACKAGES = ${BUILD_PACKAGES}

WRKDIST =		${WRKDIR}/Rebol3-${V}

REBOL3_BIN =	exec ${SETENV} ${MAKE_ENV} \
		${WRKDIR}/${BOOTSTRAP_DIR-${MACHINE_ARCH}}/bin/rebol3
SISKIN_R3 =	${WRKDIR}/Builder-${SISKIN_V}/siskin.r3

TEST_ENV +=	HOME=${WRKBUILD} \
		CI=true

do-build:
	cd ${WRKBUILD} && ${REBOL3_BIN} \
		${SISKIN_R3} make/rebol3.nest \
		-vv -c 'Rebol/Bulk ${ALL_TARGET}'
	${WRKBUILD}/build/rebol3-bulk-${ALL_TARGET} -v

do-install:
	${INSTALL_PROGRAM} -s -m 0755 \
		${WRKBUILD}/build/rebol3-bulk-${ALL_TARGET} \
		${PREFIX}/bin/rebol3
	${INSTALL_DATA_DIR} ${PREFIX}/include/rebol3
	${INSTALL_DATA} ${WRKBUILD}/src/include/*.h \
		${PREFIX}/include/rebol3
	${INSTALL_DATA_DIR} ${PREFIX}/include/rebol3/mbedtls
	${INSTALL_DATA} ${WRKBUILD}/src/include/mbedtls/*.h \
		${PREFIX}/include/rebol3/mbedtls
	${INSTALL_DATA_DIR} ${PREFIX}/include/rebol3/poly1305
	${INSTALL_DATA} ${WRKBUILD}/src/include/poly1305/*.h \
		${PREFIX}/include/rebol3/poly1305

do-test:
	cd ${WRKSRC} && exec ${SETENV} ${MAKE_ENV} ${TEST_ENV} \
		${WRKBUILD}/build/rebol3-bulk-${ALL_TARGET} \
		-s ./src/tests/run-tests.r3

BOOTSTRAPDIR=${WRKDIR}/rebol3-${V}-YYYYMMDD-${MACHINE_ARCH}
bootstrap: patch
	${_PBUILD} rm -rf -- ${BOOTSTRAPDIR}
	${_PBUILD} mkdir -p ${BOOTSTRAPDIR}/{bin,lib}
	${_PBUILD} cd ${WRKBUILD} && ${REBOL3_BIN} \
		${SISKIN_R3} make/rebol3.nest \
		-vv -c 'Rebol/Core ${ALL_TARGET}'
	${INSTALL_PROGRAM} -s -m 0755 \
		${WRKBUILD}/build/rebol3-core-${ALL_TARGET} \
		${BOOTSTRAPDIR}/bin/rebol3
	ldd ${BOOTSTRAPDIR}/bin/rebol3 \
		| sed -ne 's,.* \(/.*/lib/lib.*\.so.[.0-9]*\)$$,\1,p' \
		| xargs -r -J % ${_PBUILD} cp % ${BOOTSTRAPDIR}/lib || true
	chmod -R a+rX ${BOOTSTRAPDIR}

.include <bsd.port.mk>
