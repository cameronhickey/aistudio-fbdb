require 'elasticsearch/dsl'


class AdsController < ApplicationController

    def show
        if params[:archive_id]
            @ad = Ad.find_by(archive_id: params[:archive_id]) 
        elsif params[:ad_id]
            @ad = Ad.find(ad_id: params[:ad_id])
        end


        @fbpac_ad = @ad.fbpac_ad
        @writable_ad = @ad.writable_ad

        respond_to do |format|
          format.html
          format.json { render json: {
            ad: @ad.as_json(include: [:fbpac_ad, :writable_ad, :topics])
          } }
        end
    end

    def overview
        @ads_count       = Ad.count
        @fbpac_ads_count = FbpacAd.count
        @big_spenders = BigSpender.preload(:writable_page).preload(:ad_archive_report_page).preload(:page)
        @top_advertisers = ActiveRecord::Base.connection.exec_query('SELECT ad_archive_report_pages.page_id, 
            ad_archive_report_pages.page_name, 
            sum(amount_spent_since_start_date)  sum_amount_spent
            FROM ad_archive_report_pages 
            WHERE ad_archive_report_pages.ad_archive_report_id = $1
            GROUP BY page_id, page_name 
            ORDER BY sum_amount_spent desc limit $2', nil, 
            [[nil, AdArchiveReport.where(kind: 'lifelong', loaded: true).order(:scrape_date).last.id], [nil, 20]]
            ).rows
        @top_disclaimers = ActiveRecord::Base.connection.exec_query('SELECT 
            payers.id,
            ad_archive_report_pages.disclaimer, 
            sum(amount_spent_since_start_date)  sum_amount_spent 
            FROM ad_archive_report_pages 
            JOIN payers
            ON disclaimer = name
            WHERE ad_archive_report_pages.ad_archive_report_id = $1 
            GROUP BY disclaimer, payers.id 
            ORDER BY sum_amount_spent desc limit $2', nil, 
            [[nil, AdArchiveReport.where(kind: 'lifelong', loaded: true).order(:scrape_date).last.id], [nil, 20]]
            ).rows
        respond_to do |format|
            format.html 
        end
    end

    def index
        # eventually the search method?
        @ads = Ad.includes(:fbpac_ad).paginate(page: params[:page], per_page: 30)

        respond_to do |format|
            format.html 
            format.json { render json: @ads.as_json(include: :fbpac_ad) }
        end
    end

    def no_payer
        @fbpac_ads = FbpacAd.where(paid_for_by: nil, lang: "en-US").order("created_at desc").paginate(page: params[:page], per_page: 30)
        respond_to do |format|
            format.html 
            format.json { render json: @fbpac_ads }
        end
    end

    def search
        # keywordsearch: ad text
        # keywordsearch URL?
        # some sort of search UTM params
        # keywordsearch: targeting 
        # filter: disclaimer, advertiser
        # keywordsearch disclaimers?
        # time based filter

        
        search = params[:search]
        page_id = params[:page_id]
        publish_date = nil # "2019-01-01"
        topic = params[:topic]

        query = Elasticsearch::DSL::Search.search do
          query do
            bool do
              must do
                multi_match do
                  query search
                    fields [:text, :payer_name, :page_name]
                end if search
              end if search
              filter do
                term page_id: page_id.to_i if page_id
                range :creation_date do  
                  gte publish_date 
                end if publish_date
                terms topics: [topic] if topic
                # script script: "_source._content.length() == 0" if params[:no_payer]
               


                # targeting is included via FBPAC. But what do we do about searching ads that don't have an ATIAd counterpart??
                # TODO: targeting, if we end up getting it.
                # TODO: filter by  states seen, impressions minimums/maximums, topics

              end if [page_id, publish_date, topic].any?{|a| a }
            end
          end
        end
        @ads = Ad.search query 
        respond_to do |format|
            format.html 
            format.json { render json: @ads.as_json(include: :fbpac_ad) }
        end
    end
end
