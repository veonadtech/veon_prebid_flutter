package appconfig

import (
	"github.com/veonadtech/dsp-bidder/bidding"
	"github.com/veonadtech/dsp-bidder/enrichers/udger"
	"github.com/veonadtech/go-openrtb"
)

type e2eGeoResolver struct{}

func (e2eGeoResolver) Resolve(req *openrtb.BidRequest, _ *bidding.Context) error {
	if req.Device != nil && req.Device.Geo == nil {
		req.Device.Geo = &openrtb.Geo{Country: "UZB"}
	}
	return nil
}

func (e2eGeoResolver) ConvertCountryCode(country string) string { return country }

type e2eUdgerParser struct{}

func (e2eUdgerParser) Parse(string) (*udger.Info, error) {
	return &udger.Info{}, nil
}
