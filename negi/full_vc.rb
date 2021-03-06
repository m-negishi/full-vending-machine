class FullVendingMachine
  attr_reader :charged, :sales
  # 使用可能なお金
  AVAILABLE_MONEY = [10, 50, 100, 500, 1000].sort { |a, b| b <=> a }.freeze

  def initialize
    # 投入金額
    @charged = 0

    # 売上
    @sales = 0

    # 在庫
    @stocks_management = StockManagement.new
    @stocks_management.add_stock('cola', Drink.new('コーラ', 120), 5)
    @stocks_management.add_stock('redbull', Drink.new('レッドブル', 200), 5)
    @stocks_management.add_stock('water', Drink.new('水', 100), 5)

    # 釣り銭ストック
    @change_stocks = ChangeStocksManagement.new
    AVAILABLE_MONEY.each { |money| @change_stocks.add_stocks(money, 10) }
  end

  # お金投入
  def charging(money)
    return money unless AVAILABLE_MONEY.include?(money)
    @change_stocks.add_stocks(money)
    @charged += money
  end

  # 投入金額返却
  def refund
    refund_charged = @charged
    @charged = 0
    refund_charged
  end

  # 在庫リスト
  def all_stocks
    @stocks_management.all_stocks
  end

  def change_stocks
    @change_stocks.all_stocks
  end

  # 購入可否チェック
  def purchasable?(drink_name)
    return false unless @charged >= @stocks_management.drink_info(drink_name).price
    return false unless @stocks_management.drink_stocks(drink_name) > 0
    true
  end

  # 購入可能リスト
  def purchasable_list
    purchasable_list = []

    all_stocks.each do |drink_name, value|
      purchasable_list << drink_name.to_s if purchasable?(drink_name)
    end

    purchasable_list
  end

  # 購入
  def purchase(drink_name)
    drink_price = @stocks_management.drink_info(drink_name).price

    if purchasable?(drink_name) && changable?(drink_price)
      # 在庫減らす
      @stocks_management.reduce_stock(drink_name)
      # 売上反映
      @sales += drink_price
      # 釣り銭返却処理
      change(drink_price)
    end
  end

  private

  ### 釣り銭操作 ###

  # 釣り銭返却処理
  def change(drink_price)
    @charged -= drink_price
    # 釣り銭ストック減らす
    @change_stocks = @temp_change_stocks
    # 釣り銭返却
    refund
  end

  # 釣り銭返却可否
  def changable?(drink_price)
    calc_reduce_change_stocks(@charged - drink_price)
  end


  # 釣り銭ストック計算
  def calc_reduce_change_stocks(money)

    # 最終的な返却枚数のリスト
    last_change_count_list = Hash.new{ |hash, key| hash[key] = 0 }
    # 計算用釣り銭ストック
    @temp_change_stocks = @change_stocks.dup
    # 返却可能かどうか
    flag = true

    while money > 0 do
      # 再帰計算用
      temp_change_count_list = {}

      AVAILABLE_MONEY.each do |value|
        # 釣り銭ストックが無い場合
        if @temp_change_stocks[value] <= 0
          temp_change_count_list[value] = 0
          next
        end

        # 返す枚数計算
        money_count = money.div(value)
        temp_change_count_list[value] = money_count
        # 残りの返却額計算
        money -= value * money_count
      end

      temp = 0
      temp_change_count_list.each_value do |value|
        temp += value
      end

      # 返却できる枚数がゼロの場合
      if temp == 0
        flag = false
        break
      end

      temp_change_count_list.each do |key, value|
        # ストックから返却できる場合
        if @temp_change_stocks[key] >= value
          @temp_change_stocks[key] -= value
          last_change_count_list[key] += value
        # ストックが不足している場合再計算
        else
          temp_change_count_list[key] -= @temp_change_stocks[key]
          last_change_count_list[key] += @temp_change_stocks[key]
          @temp_change_stocks[key] = 0

          # 再計算が必要な金額を取得
          temp_change_count_list.each do |key, value|
            money += key * value
          end
          break
        end
      end
    end

    if flag
      @temp_change_stocks
    else
      flag
    end
  end

end

class StockManagement
  attr_reader :all_stocks

  def initialize
    @all_stocks = {}
  end

  # 在庫追加
  def add_stock(drink_name, drink, stocks)
    @all_stocks.store(:"#{drink_name}", { info: drink, stocks: stocks })
  end

  # 在庫減少
  def reduce_stock(drink_name)
    @all_stocks[:"#{drink_name}"][:stocks] -= 1
  end

  # ドリンク在庫情報
  def drink_info(drink_name)
    @all_stocks[:"#{drink_name}"][:info]
  end

  # ドリンク在庫数
  def drink_stocks(drink_name)
    @all_stocks[:"#{drink_name}"][:stocks]
  end
end

class Drink
  attr_reader :name, :price

  def initialize(name, price)
    @name = name
    @price = price
  end
end

class ChangeStocksManagement
  attr_reader :all_stocks

  def initialize
    @all_stocks = {}
  end

  # 指定したお金のストックを追加する
  def add_stocks(money, stocks=1)
    @all_stocks.merge!({money => stocks}){ |key, v1, v2| v1 + v2 }
  end

  # 指定したお金のストックを減らす
  def reduce_stock(money, stocks)
    if enough_stocks?(money, stocks)
      @all_stocks[money] -= stocks
    else
      false
    end
  end

  def enough_stocks?(money, stocks)
    @all_stocks[money] <= stocks
  end
end

=begin

full_vc = FullVendingMachine.new
full_vc.charging(500)
full_vc.purchasable_list

=end
