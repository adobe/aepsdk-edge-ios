@Library('sdk-ci-script@v2') _

node('bourbon-platform-ios') {
	amsdkIOSPipeline{
	    format = false
	    build = true
	    unitTest = true
	    unitTestCoverage = true
	    functionalTest = true
	    internalPublish = false
	    publish = false
	    createPRs = false
	    tag = false
	}
}
