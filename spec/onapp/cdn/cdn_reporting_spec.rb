require 'spec_helper'
require './groups/cdn_reporting_actions'

describe 'CDN Reporting ->' do
  before :all do
    @cra = CdnReportingActions.new.precondition
    @cp_version = @cra.version
  end

  let (:cdn_reporting)  { @cra.cdn_reporting }
  let (:start_date)     {'2017-04-01'}
  let (:end_date)       {'2017-04-08'}
  let (:wrong_end_date) {'2016-04-08'}

  context 'Overview ->' do
    def overview_options(**kw)
      @overview_options = {
        overview: {
          frequency: kw[:frequency] || 1,
          start_date: kw[:start_date] || "#{start_date}",
          end_date: kw[:end_date] || "#{wrong_end_date}"
        }
      }
    end

    context 'positive ->' do
      it 'is get page with default time range' do
        @cra.get(cdn_reporting.route_reporting_overview)
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.overview.count).to eq 5
        expect(@cra.conn.page.body.overview['overview_top_five_http_error_codes_table'].class).to eq Array
        expect(@cra.conn.page.body.overview['overview_top_five_resources_table'].class).to eq Array
        expect(@cra.conn.page.body.overview['overview_top_five_locations_table'].class).to eq Array
        expect(@cra.conn.page.body.overview['overview_top_five_locations_table'].class).to eq Array
        expect(@cra.conn.page.body.overview['overview_top_five_visitor_locations_pie_chart'].class).to eq Array
      end

      it 'is get page with 1 day range' do
        @cra.get(cdn_reporting.route_reporting_overview, { overview: {frequency: 2} })
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 hour range' do
        @cra.get(cdn_reporting.route_reporting_overview, { overview: {frequency: 1} })
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 minute range' do
        @cra.get(cdn_reporting.route_reporting_overview, { overview: {frequency: 0} })
        expect(@cra.conn.page.code).to eq '200'
      end
    end

    context 'negative ->' do
      it 'is not get with frequency > 2 and start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_overview, overview_options(frequency: 234, end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date and Frequency 234 is unknown. Expected values: [0, 1, 2]"]
        end

      it 'is not get with frequency > 2' do
        @cra.get(cdn_reporting.route_reporting_overview, {overview: {frequency: 234} })
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Frequency 234 is unknown. Expected values: [0, 1, 2]"]
      end

      it 'is not get with frequency start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_overview, overview_options(end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
      end

      it 'is not get with start_date is empty' do
        @cra.get(cdn_reporting.route_reporting_overview, overview_options(start_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
      end

      it 'is not get with end_date is empty' do
        @cra.get(cdn_reporting.route_reporting_overview, overview_options(end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
      end

      it 'is not get with start_date and end_date are empty' do
        @cra.get(cdn_reporting.route_reporting_overview, overview_options(start_date: '', end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set and End date is not set"]
      end

      it 'is not get with start_date and end_date are text' do
        @cra.get(cdn_reporting.route_reporting_overview, overview_options(start_date: 'text', end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
      end

      it 'is not get with end_date is text' do
        @cra.get(cdn_reporting.route_reporting_overview, overview_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end
    end
  end

  context 'Cache Statistics ->' do
    def cache_options(**kw)
      @cache_options = {
        cache_statistics: {
          frequency: kw[:frequency] || 2,
          filter_type: kw[:filter_type] || 0,
          start_date: kw[:start_date] || "#{start_date}",
          end_date: kw[:end_date] || "#{end_date}"
        }
      }
    end

    context 'positive ->' do
      it 'is get page with default time range' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics)
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.cache_statistics.count).to eq 2
        expect(@cra.conn.page.body.cache_statistics['cache_statistic_line_chart'].class).to eq Array
        expect(@cra.conn.page.body.cache_statistics['cache_statistic_table'].class).to eq Array
      end

      it 'is get page with 1 day range' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options)
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 hour range' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 1))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 minute range' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 0))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 day range and type is hit/miss' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 2, filter_type: 1))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 hour range and type is hit/miss' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 1, filter_type: 1))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 minute range and type is hit/miss' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 0, filter_type: 1))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 day range and type is speed' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 2, filter_type: 2))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 hour range and type is speed' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 1, filter_type: 2))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 minute range and type is speed' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 0, filter_type: 2))
        expect(@cra.conn.page.code).to eq '200'
      end
    end

    context 'negative ->' do
      it 'is not get page with frequency > 2' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(frequency: 234))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Frequency 234 is unknown. Expected values: [0, 1, 2]"]
      end

      it 'is not get page with start_date is empty' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(start_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
      end


      it 'is not get page with end_date is empty' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
      end

      it 'is not get page with start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
      end

      it 'is not get with start_date and end_date are text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(start_date: 'text', end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
      end

      it 'is not get with end_date is text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_cache_statistics, cache_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end
    end
  end

  context 'Top Files ->' do
    it 'is get page with 1 day range' do
      @cra.get(cdn_reporting.route_reporting_top_files)
      expect(@cra.conn.page.code).to eq '200'
      expect(@cra.conn.page.body.top_files.count).to eq 1
      expect(@cra.conn.page.body.top_files['top_fifty_files_table'].class).to eq Array
    end

    it 'is not get page with start_date > end_date' do
      @cra.get(cdn_reporting.route_reporting_top_files, { top_files: {start_date: "#{start_date}", end_date: "#{wrong_end_date}"} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
    end

    it 'is not get page with unexisting entity_id' do
      wrong_entity_id = Faker::Number.number(12)
      @cra.get(cdn_reporting.route_reporting_top_files, { top_files: {entity_id: wrong_entity_id, start_date: "#{start_date}", end_date: "#{end_date}"} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["getTopFiftyFilesTable request has faced Thrift Error"] if @cp_version < 5.6
      expect(@cra.conn.page.body.errors).to eq ["Entity CDN Resource with ID #{wrong_entity_id} was not found at CP"] if @cp_version >= 5.6
    end

    it 'is not get page with start_date is empty' do
      @cra.get(cdn_reporting.route_reporting_top_files, { top_files: {start_date: '', end_date: "#{end_date}"} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
    end

    it 'is not get page with start_date is not set' do
      @cra.get(cdn_reporting.route_reporting_top_files, { top_files: {end_date: "#{wrong_end_date}"} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
    end

    it 'is not get page with end_date is empty' do
      @cra.get(cdn_reporting.route_reporting_top_files, { top_files: {start_date: "#{start_date}", end_date: ''} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
    end

    it 'is not get with start_date and end_date are text' do
      skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
      @cra.get(cdn_reporting.route_reporting_top_files, { top_files: {start_date: "text", end_date: 'text'} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
    end

    it 'is not get with end_date is text' do
      skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
      @cra.get(cdn_reporting.route_reporting_top_files, { top_files: {end_date: 'text'} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
    end
  end

  context 'Top Referrers ->' do
    it 'is get page with 1 day range' do
      @cra.get(cdn_reporting.route_reporting_top_referrers)
      expect(@cra.conn.page.code).to eq '200'
      expect(@cra.conn.page.body.top_referrers.count).to eq 1
      expect(@cra.conn.page.body.top_referrers['top_fifty_referers_table'].class).to eq Array
    end

    it 'is not get page with start_date > end_date' do
      @cra.get(cdn_reporting.route_reporting_top_referrers, { top_referrers: {start_date: "#{start_date}", end_date: "#{wrong_end_date}"} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
    end

    it 'is not get page with start_date is empty' do
      @cra.get(cdn_reporting.route_reporting_top_referrers, { top_referrers: {start_date: '', end_date: "#{wrong_end_date}"} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
    end

    it 'is not get page with end_date is empty' do
      @cra.get(cdn_reporting.route_reporting_top_referrers, { top_referrers: {start_date: "#{start_date}", end_date: ''} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
    end

    it 'is not get with start_date and end_date are text' do
      skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
      @cra.get(cdn_reporting.route_reporting_top_referrers, { top_referrers: {start_date: "text", end_date: 'text'} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
    end

    it 'is not get with end_date is text' do
      skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
      @cra.get(cdn_reporting.route_reporting_top_referrers, { top_referrers: {end_date: 'text'} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
    end
  end

  context 'Status Codes ->' do
    def status_options(**kw)
      @status_options = {
          status_codes: {
              frequency: kw[:frequency] || 2,
              start_date: kw[:start_date] || "#{start_date}",
              end_date: kw[:end_date] || "#{end_date}"
          }
      }
    end

    it 'is get page with default time range' do
      @cra.get(cdn_reporting.route_reporting_status_codes)
      expect(@cra.conn.page.code).to eq '200'
      expect(@cra.conn.page.body.status_codes.count).to eq 3
      expect(@cra.conn.page.body.status_codes['status_code_line_chart'].class).to eq Array
      expect(@cra.conn.page.body.status_codes['status_code_table'].class).to eq Array
      expect(@cra.conn.page.body.status_codes['http_error_code_table'].class).to eq Array
    end

    it 'is get page with 1 day range' do
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options)
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'is get page with 1 hour range' do
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options(frequency: 1))
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'is get page with 1 minute range' do
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options(frequency: 0))
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'is not get page with start_date > end_date' do
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options(end_date: "#{wrong_end_date}"))
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
    end

    it 'is not get page with start_date is empty' do
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options(start_date: ''))
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
    end

    it 'is not get page with end_date is empty' do
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options(end_date: ''))
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
    end

    it 'is not get with start_date and end_date are text' do
      skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options(start_date: 'text', end_date: 'text'))
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
    end

    it 'is not get with end_date is text' do
      skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options(end_date: 'text'))
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
    end

    it 'is not get page with unexisting entity_id' do
      wrong_entity_id = Faker::Number.number(12)
      @cra.get(cdn_reporting.route_reporting_status_codes, status_options.merge({ status_codes: {entity_id: wrong_entity_id} }))
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["getStatusCodeLineChart request has faced Thrift Error and getStatusCodeTable request has faced Thrift Error"] if @cp_version < 5.6
      expect(@cra.conn.page.body.errors).to eq ["Entity CDN Resource with ID #{wrong_entity_id} was not found at CP"] if @cp_version >= 5.6
    end
  end

  context 'Visitors ->' do
    it 'is get page with default time range' do
      @cra.get(cdn_reporting.route_reporting_visitors)
      expect(@cra.conn.page.code).to eq '200'
      expect(@cra.conn.page.body.visitors.count).to eq 2
      expect(@cra.conn.page.body.visitors['top_five_visitor_countries_line_chart'].class).to eq Array
      expect(@cra.conn.page.body.visitors['visitor_country_table'].class).to eq Array
    end

    it 'is not get page with start_date > end_date' do
      @cra.get(cdn_reporting.route_reporting_visitors, { visitors: {start_date: "#{start_date}", end_date: "#{wrong_end_date}"} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
    end

    it 'is not get page with start_date is empty' do
      @cra.get(cdn_reporting.route_reporting_visitors, { visitors: {start_date: '', end_date: "#{end_date}"} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
    end

    it 'is not get page with end_date is empty' do
      @cra.get(cdn_reporting.route_reporting_visitors, { visitors: {start_date: "#{start_date}", end_date: ''} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
    end

    it 'is not get with start_date and end_date are text' do
      skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
      @cra.get(cdn_reporting.route_reporting_visitors, { visitors: {start_date: 'text', end_date: 'text'} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
    end

    it 'is not get with end_date is text' do
      skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
      @cra.get(cdn_reporting.route_reporting_visitors, { visitors: {end_date: 'text'} })
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
    end
  end

  context 'Stream Bandwidth ->' do
    def bandwidth_options(**kw)
      @bandwidth_options = {
        bandwidth_statistics: {
          type: kw[:type] || 'GB',
          start_date: kw[:start_date] || "#{start_date} 00:00",
          end_date: kw[:end_date] || "#{end_date} 00:00"
        }
      }
    end

    context 'positive ->' do
      it 'is get page with default time range' do
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth)
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.bandwidth_statistics.count).to eq 1
        expect(@cra.conn.page.body.bandwidth_statistics.class).to eq Hashie::Mash
        expect(@cra.conn.page.body.bandwidth_statistics.cache_statistic_line_chart.count).to eq 2
        expect(@cra.conn.page.body.bandwidth_statistics.cache_statistic_line_chart['data'].class).to eq Array
        expect(@cra.conn.page.body.bandwidth_statistics.cache_statistic_line_chart['data_total'].class).to eq Hashie::Mash
      end

      it 'is get page with GB type' do
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options)
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with MBPS type' do
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options(type: 'MBPS'))
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.bandwidth_statistics.count).to eq 1
        expect(@cra.conn.page.body.bandwidth_statistics.class).to eq Hashie::Mash
        expect(@cra.conn.page.body.bandwidth_statistics.cache_statistic_line_chart.count).to eq 2
        expect(@cra.conn.page.body.bandwidth_statistics.cache_statistic_line_chart['data'].class).to eq Array
        expect(@cra.conn.page.body.bandwidth_statistics.cache_statistic_line_chart['data_total'].class).to eq Hashie::Mash
      end
    end

    context 'negative ->' do
      it 'is not get page with start_date is not set' do
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options(start_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
      end


      it 'is not get page with end_date is not set' do
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options(end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
      end

      it 'is not get page with start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options(end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
      end

      it 'is not get page with incorrect type' do
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options(type: '123'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Type 123 is unknown. Expected values: gb,mbps"]
      end

      it 'is not get page with incorrect type and start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options(type: '123', end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date and Type 123 is unknown. Expected values: gb,mbps"]
      end

      it 'is not get with start_date and end_date are text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options(start_date: 'text', end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
      end

      it 'is not get with end_date is text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_stream_bandwidth, bandwidth_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end
    end
  end

  context 'Concurrent Statistics->' do
    def concurrent_options(**kw)
      @concurrent_options = {
          concurrent_statistics: {
              start_date: kw[:start_date] || "#{start_date} 00:00",
              end_date: kw[:end_date] || "#{end_date} 00:00",
              resources: kw[:resources] || "",
              locations: kw[:locations] || ""
          }
      }
    end

    context 'positive ->' do
      it 'is get page with default time range' do
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics)
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.concurrent_statistics.count).to eq 1
        expect(@cra.conn.page.body.concurrent_statistics.stream_concurrent_line_chart.class).to eq Array
        # expect(@cra.conn.page.body.concurrent_statistics.stream_concurrent_line_chart.count).to eq 2
      end

      it 'is get page with incorrect format of resources(should return everything)' do
        # CORE-9863, CORE-10626
        skip 'it is not supported in CP < v5.6' if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(resources: '' ))
        expect(@cra.conn.page.code).to eq '200'
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(resources: ['']))
        expect(@cra.conn.page.code).to eq '200'
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(resources: '1111111111111'))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with incorrect format of locations(should return everything)' do
        # CORE-9863, CORE-10626
        skip 'it is not supported in CP < v5.6' if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(locations: ['']))
        expect(@cra.conn.page.code).to eq '200'
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(locations: '' ))
        expect(@cra.conn.page.code).to eq '200'
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(locations: ['1111111111111']))
        expect(@cra.conn.page.code).to eq '200'
      end
    end

    context 'negative ->' do
      it 'is not get page with start_date is not set' do
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(start_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
      end

      it 'is not get page with end_date is not set' do
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
      end

      it 'is not get page with start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
      end

      it 'is not get page with start_date and end_date are empty' do
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(start_date: "", end_date: ""))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set and End date is not set"]
      end

      it 'is not get page with date is text' do
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end

      it 'is not get page with incorrect date(2017-02-30)' do
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(end_date: '2017-02-30'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end

      it 'is not get with start_date and end_date are text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(start_date: 'text', end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
      end

      it 'is not get with end_date is text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_concurrent_statistics, concurrent_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end
    end
  end

  context 'Admin ->' do
    def admin_options(**kw)
      @admin_options = {
        admin: {
          start_date: kw[:start_date] || "#{start_date}",
          end_date: kw[:end_date] || "#{end_date}",
          frequency: kw[:frequency] || 2
        }
      }
    end

    context 'admin page ->' do
      it 'is get page with default time range' do
        @cra.get(cdn_reporting.route_reporting_admin)
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.admin.count).to eq 4
        expect(@cra.conn.page.body.admin['cache_statistic_admin_line_chart'].class).to eq Array
        expect(@cra.conn.page.body.admin['top_five_resources_admin_table'].class).to eq Array
        expect(@cra.conn.page.body.admin['top_five_locations_admin'].class).to eq Array
        expect(@cra.conn.page.body.admin['top_five_http_error_codes_admin_table'].class).to eq Array
      end

      it 'is get page with 1 day range' do
        @cra.get(cdn_reporting.route_reporting_admin, admin_options)
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 hour range' do
        @cra.get(cdn_reporting.route_reporting_admin, admin_options(frequency: 1))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is get page with 1 minute range' do
        @cra.get(cdn_reporting.route_reporting_admin, admin_options(frequency: 0))
        expect(@cra.conn.page.code).to eq '200'
      end

      it 'is not get page with start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_admin, admin_options(end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
      end

      it 'is not get page with start_date is empty' do
        @cra.get(cdn_reporting.route_reporting_admin, admin_options(start_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
      end

      it 'is not get page with end_date is empty' do
        @cra.get(cdn_reporting.route_reporting_admin, admin_options(end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
      end

      it 'is not get with start_date and end_date are text' do
        @cra.get(cdn_reporting.route_reporting_admin, admin_options(start_date: 'text', end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
      end

      it 'is not get with end_date is text' do
        @cra.get(cdn_reporting.route_reporting_admin, admin_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end
   end

    context '50 cdn resources ->' do
      it 'is get top_50_cdn_reportings' do
        @cra.get(cdn_reporting.route_reporting_top_50_cdn_resources)
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.top_50_cdn_resources.count).to eq 1
        expect(@cra.conn.page.body.top_50_cdn_resources['top_fifty_resources_admin_table'].class).to eq Array
      end

      it 'is not get page with start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_top_50_cdn_resources, admin_options(end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
      end

      it 'is not get page with start_date is empty' do
        @cra.get(cdn_reporting.route_reporting_top_50_cdn_resources, admin_options(start_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
      end

      it 'is not get page with end_date is empty' do
        @cra.get(cdn_reporting.route_reporting_top_50_cdn_resources, admin_options(end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
      end

      it 'is not get with start_date and end_date are text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_top_50_cdn_resources, admin_options(start_date: 'text', end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
      end

      it 'is not get with end_date is text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_top_50_cdn_resources, admin_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end
    end

    context 'locations ->' do
      it 'is get locations' do
        @cra.get(cdn_reporting.route_reporting_locations)
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.locations.count).to eq 1
        expect(@cra.conn.page.body.locations['location_admin_table'].class).to eq Array
      end

      it 'is not get page with start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_locations, admin_options(end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
      end

      it 'is not get page with start_date is empty' do
        @cra.get(cdn_reporting.route_reporting_locations, admin_options(start_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
      end

      it 'is not get page with end_date is empty' do
        @cra.get(cdn_reporting.route_reporting_locations,  admin_options(end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
      end

      it 'is not get with start_date and end_date are text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_locations, admin_options(start_date: 'text', end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
      end

      it 'is not get with end_date is text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_locations, admin_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end
    end

    context 'top 50 http errors ->' do
      it 'is get top_50_http_errors' do
        @cra.get(cdn_reporting.route_reporting_top_50_http_errors)
        expect(@cra.conn.page.code).to eq '200'
        expect(@cra.conn.page.body.top_50_http_errors.count).to eq 1
        expect(@cra.conn.page.body.top_50_http_errors['top_fifty_http_error_codes_admin_table'].class).to eq Array
      end

      it 'is not get page with start_date > end_date' do
        @cra.get(cdn_reporting.route_reporting_top_50_http_errors, admin_options(end_date: "#{wrong_end_date}"))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is lower than Start date"]
      end

      it 'is not get page with start_date is empty' do
        @cra.get(cdn_reporting.route_reporting_top_50_http_errors, admin_options(start_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is not set"]
      end

      it 'is not get page with end_date is empty' do
        @cra.get(cdn_reporting.route_reporting_top_50_http_errors, admin_options(end_date: ''))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is not set"]
      end

      it 'is not get with start_date and end_date are text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_top_50_http_errors, admin_options(start_date: 'text', end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Start date is invalid"]
      end

      it 'is not get with end_date is text' do
        skip "it is not fixed in CP < v5.6 CORE-9864" if @cp_version < 5.6
        @cra.get(cdn_reporting.route_reporting_top_50_http_errors, admin_options(end_date: 'text'))
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["End date is invalid"]
      end
    end
  end
end
