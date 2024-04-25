# frozen_string_literal: true

module MyTankInfo
  class TankReconciliationRecordCollection
    attr_reader :data, :size, :site_id, :reconciliation_period, :started_at, :ended_at,
      :volume_uom, :height_uom

    def self.from_response(response, reconciliation_period:)
      body = response.body

      @collection = new(
        data: body.map { |attrs| TankReconciliationRecord.new(attrs) },
        reconciliation_period: reconciliation_period
      )
    end

    def initialize(data:, reconciliation_period:, auto_fill_needed: nil)
      @data = data
      @size = @data.size
      @reconciliation_period = reconciliation_period

      @site_id = @data.first&.site_id
      @started_at = @data.min_by(&:started_at)&.started_at
      @ended_at = @data.max_by(&:started_at)&.started_at

      @volume_uom = @data.first&.volume_uom
      @height_uom = @data.first&.height_uom

      @auto_fill_needed = auto_fill_needed
    end

    def tanks
      @data.map { |record|
        base_records = @data.select { _1.tank_number == record.tank_number }.sort_by(&:started_at)
        records =
          if @auto_fill_needed.nil?
            base_records
          elsif @auto_fill_needed
            base_records.select { _1.auto_fill_needed == true }
          else
            base_records.select { _1.auto_fill_needed == false }
          end

        summary =
          TankReconciliationRecordSummary.new(
            records,
            capacity: record.total_tanks_capacity,
            reconciliation_period: @reconciliation_period
          )

        Tank.new(
          name: record.name,
          product_name: record.product_name,
          tank_number: record.tank_number,
          tank_numbers: record.tank_numbers,
          capacity: record.total_tanks_capacity,
          reconciliation_records: records,
          reconciliation_summary: summary,
          passed?: summary.passed?,
          failed?: summary.failed?
        )
      }.uniq { |tank| tank.name }
        .sort_by(&:tank_number)
    end
  end
end
