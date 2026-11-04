// This file is copied into cmd/e2e in a checkout of veonadtech/dsp-bidder.
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/veonadtech/dsp-bidder/segments"
	"github.com/veonadtech/dsp-bidder/tests"
)

func main() {
	if os.Getenv("DSP_E2E_MODE") != "1" {
		log.Fatal("DSP_E2E_MODE=1 is required")
	}
	campaign := os.Getenv("DSP_E2E_CAMPAIGN")
	if campaign == "" {
		log.Fatal("DSP_E2E_CAMPAIGN is required")
	}
	suite := tests.ConfigureTestEnv(campaign, &segments.Mock{})
	log.Println("Listening for local DSP E2E bids on :9800")
	log.Fatal(http.ListenAndServe(":9800", suite.R))
}
